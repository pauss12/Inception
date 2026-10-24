#!/bin/sh
# Si cualquier comando falla, el script se para (y Docker reinicia el contenedor)
set -e

# 1. Leer las contraseñas de los secrets (Docker los deja en /run/secrets/)
DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# 2. Preparar la base de datos solo la primera vez
#    Si existe la carpeta "mysql", el volumen ya tiene una base de datos creada
if [ ! -d /var/lib/mysql/mysql ]; then

    # 2.1 Crear las tablas internas de MariaDB
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 2.2 Arrancar MariaDB temporalmente, en segundo plano (&) y sin red,
    #     solo para poder configurarla
    mariadbd --user=mysql --skip-networking &

    # 2.3 Esperar a que responda
    until mariadb-admin ping --silent; do
        sleep 1
    done

    # 2.4 Configurar: base de datos de WordPress, su usuario y la contraseña de root
    #     '%' = el usuario puede conectarse desde cualquier contenedor de la red
    mariadb <<EOF
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF

    # 2.5 Apagar la MariaDB temporal (root ya tiene contraseña) y esperar a que termine
    mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown
    wait
fi

# 3. Arrancar MariaDB de verdad como PID 1
#    exec: MariaDB sustituye a este script (no queda un proceso "sh" por encima)
echo "Arrancando MariaDB..."
exec mariadbd --user=mysql
