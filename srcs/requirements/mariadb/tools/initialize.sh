#!/bin/bash
set -e

# 1. Leer contraseñas desde Docker Secrets de forma segura
if [ -f "/run/secrets/db_password" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
fi

# 2. ADAPTACIÓN A ALPINE: Inicializar la carpeta física si es la primera vez
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

    # 3. ARRANCAR EN SEGUNDO PLANO SIN 'SERVICE' (Usando el binario directo de Alpine)
    /usr/bin/mysqld_safe --user=mysql --skip-networking &
    pid="$!"

    # 4. EL BUCLE DE ESPERA (Esto sí es correcto y se mantiene)
    until mariadb-admin ping --silent; do
        sleep 1
    done

    # 5. EJECUTAR LAS QUERIES
    mariadb -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;"
    mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
    mariadb -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%' WITH GRANT OPTION;"
    mariadb -e "FLUSH PRIVILEGES;"

    # 6. APAGADO LIMPIO DEL PROCESO TEMPORAL
    mariadb-admin -u root shutdown
    wait "$pid"
fi

# 7. EL EXEC FINAL (Obligatorio para el PID 1 exigido por el sujeto)
echo "🚀 Arrancando MariaDB como PID 1..."
exec /usr/bin/mysqld_safe --user=mysql
