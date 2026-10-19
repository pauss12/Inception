#!/bin/sh
set -e

# 1. Leer las contraseñas desde Docker Secrets (igual que en mariadb)
if [ -f "/run/secrets/db_password" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
fi
if [ -f "/run/secrets/wp_admin_password" ]; then
    WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
fi
if [ -f "/run/secrets/wp_user_password" ]; then
    WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
fi


# 2. Esperar a que MariaDB esté lista antes de hacer nada
tries=0
until mariadb-admin ping -h mariadb --skip-ssl --silent; do
    tries=$((tries+1))
    if [ "$tries" -ge 60 ]; then
      echo "Database did not become ready in time" >&2
      exit 1
    fi
    sleep 3
done
echo "Database mariadb is ready."

# 3. Instalar WordPress solo la primera vez
#    (si ya existe wp-config.php, el volumen ya tiene WordPress instalado)
if [ ! -f "/var/www/html/wp-config.php" ]; then

    # 3.1 Descargar los archivos de WordPress
    wp core download --allow-root

    # 3.2 Crear wp-config.php con los datos de la base de datos
    wp config create --allow-root \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="mariadb:3306"

    # 3.3 Instalar WordPress y crear el administrador
    #     (el subject prohíbe que el usuario admin contenga "admin")
    wp core install --allow-root \
        --url="$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    # 3.4 Crear el segundo usuario (no administrador)
    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"
fi

# 4. Dar los archivos al usuario con el que corre PHP-FPM ("nobody" en Alpine)
chown -R nobody:nobody /var/www/html

# 5. Arrancar PHP-FPM en primer plano como PID 1
#    -F = foreground (si se fuera al fondo, el contenedor se cerraría)
echo "🚀 Arrancando PHP-FPM como PID 1..."
exec php-fpm83 -F