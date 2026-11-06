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

    # 2.2 Configurar en modo "bootstrap": MariaDB ejecuta este SQL y se apaga sola.
    #     No abre la red ni se queda en segundo plano.
    #     El primer FLUSH PRIVILEGES carga las tablas de usuarios (en bootstrap no se cargan)
    #     '%' = el usuario puede conectarse desde cualquier contenedor de la red
    mariadbd --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.global_priv WHERE User='';
DROP DATABASE IF EXISTS test;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
fi

# 3. Arrancar MariaDB de verdad como PID 1
#    exec: MariaDB sustituye a este script (no queda un proceso "sh" por encima)
echo "Arrancando MariaDB..."
exec mariadbd --user=mysql
