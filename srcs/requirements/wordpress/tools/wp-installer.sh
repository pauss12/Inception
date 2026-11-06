#!/bin/sh
# Si cualquier comando falla, el script se para (y Docker reinicia el contenedor)
set -e

# 1. Leer las contraseñas de los secrets (Docker los deja en /run/secrets/)
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# 2. Esperar a que MariaDB responda (puede tardar unos segundos en arrancar)
#    --skip-ssl: nuestra MariaDB no usa SSL dentro de la red de Docker
until mariadb-admin ping -h mariadb -u "$DB_USER" -p"$DB_PASSWORD" --skip-ssl --silent; do
    echo "Esperando a MariaDB..."
    sleep 2
done
echo "MariaDB lista."

# 3. Instalar WordPress solo la primera vez
#    Si wp-config.php ya existe, WordPress ya está instalado en el volumen.
#    (Todos los comandos "wp" trabajan en /var/www/html, el WORKDIR del Dockerfile.
#     --allow-root hace falta porque el script se ejecuta como root.)
if [ ! -f wp-config.php ]; then

    # 3.1 Descargar los archivos de WordPress
    wp core download --allow-root

    # 3.2 Crear wp-config.php: le dice a WordPress cómo conectarse a MariaDB
    wp config create --allow-root \
        --dbname="$DB_NAME" \
        --dbuser="$DB_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb:3306

    # 3.3 Crear las tablas en MariaDB y el usuario administrador
    #     (el subject prohíbe que el nombre del admin contenga "admin")
    #     Si solo se borró la carpeta de WordPress, la base de datos ya tiene las tablas
    wp core is-installed --allow-root || wp core install --allow-root \
        --url="https://$DOMAIN_NAME" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    # 3.4 Crear el segundo usuario (no administrador)
    wp user get "$WP_USER" --allow-root > /dev/null 2>&1 || \
    wp user create "$WP_USER" "$WP_USER_EMAIL" --allow-root \
        --role=author \
        --user_pass="$WP_USER_PASSWORD"
fi

# 4. Dar los archivos a "nobody", el usuario con el que trabaja PHP-FPM en Alpine
#    (así WordPress puede subir imágenes, instalar plugins...)
chown -R nobody:nobody /var/www/html

# 5. Arrancar PHP-FPM como PID 1
#    exec: PHP-FPM sustituye a este script (no queda un proceso "sh" por encima)
#    -F:   en primer plano (si se fuera al fondo, el contenedor se cerraría)
echo "Arrancando PHP-FPM..."
exec php-fpm83 -F
