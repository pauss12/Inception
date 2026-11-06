FROM alpine:3.23

# 1. Instalar PHP, sus extensiones para WordPress, curl y el cliente de MariaDB
#    --no-cache: no guarda la caché de paquetes, así la imagen ocupa menos
RUN apk add --no-cache \
	php83 \
	php83-fpm \
	php83-mysqli \
	php83-phar \
	php83-mbstring \
	php83-json \
	php83-curl \
	php83-iconv \
	php83-tokenizer \
	curl \
	mariadb-client

# 2. En Alpine el programa se llama "php83", pero WP-CLI busca "php".
#    Creamos un enlace para que "php" apunte a "php83"
RUN ln -sf /usr/bin/php83 /usr/bin/php

# 3. PHP-FPM escucha por defecto en 127.0.0.1:9000 (solo dentro de su contenedor).
#    Con "listen = PHP_PORT" acepta conexiones de otros contenedores (nginx).
#    PHP_PORT llega de .env a través de "args:" en docker-compose.yml
ARG PHP_PORT
RUN sed -i "s/^listen = .*/listen = ${PHP_PORT}/" /etc/php83/php-fpm.d/www.conf

# 4. Subir el límite de memoria de PHP (128M por defecto).
#    WP-CLI necesita más para descomprimir WordPress
RUN sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php83/php.ini

# 5. Descargar WP-CLI, la herramienta para instalar WordPress desde la terminal
RUN curl -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

# 6. Copiar el script que instala WordPress al arrancar el contenedor
COPY tools/wp-installer.sh /wp-installer.sh

# 7. Carpeta de trabajo: aquí se monta el volumen con los archivos de WordPress
WORKDIR /var/www/html

# 8. Puerto de PHP-FPM (nginx se conecta aquí)
EXPOSE ${PHP_PORT}

# 9. Al arrancar el contenedor, ejecutar el script
CMD ["sh", "/wp-installer.sh"]
