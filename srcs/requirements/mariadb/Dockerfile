FROM alpine:3.23

# 1. Instalar el servidor de MariaDB y su cliente (mariadb, mariadb-admin)
RUN apk add --no-cache mariadb mariadb-client

# 2. Crear la carpeta del socket (el "enchufe" para conectarse desde dentro del contenedor)
RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

# 3. Copiar nuestra configuración (sustituye a la de Alpine, que no acepta conexiones de red)
#    y poner el puerto que llega de .env (a través de "args:" en docker-compose.yml)
COPY conf/mariadb-conf.cnf /etc/my.cnf.d/mariadb-server.cnf
ARG DB_PORT
RUN sed -i "s/^port .*/port         = ${DB_PORT}/" /etc/my.cnf.d/mariadb-server.cnf

# 4. Copiar el script que prepara la base de datos al arrancar el contenedor
COPY tools/initialize.sh /initialize.sh

# 5. Puerto de MariaDB (WordPress se conecta aquí)
EXPOSE ${DB_PORT}

# 6. Al arrancar el contenedor, ejecutar el script
CMD ["sh", "/initialize.sh"]
