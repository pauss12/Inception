FROM alpine:3.23

# 1. Instalar PHP y lo necesario para WordPress
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
	curl \
	mariadb-client

# 2. En Alpine el binario se llama "php83"; WP-CLI busca "php", por lo que se hace un 
# enlace simbólico para que "php" apunte a "php83"
RUN ln -sf /usr/bin/php83 /usr/bin/php

# 3. PHP-FPM escucha por defecto en 127.0.0.1:9000 (solo dentro del contenedor).
#    Lo cambiamos a "9000" para que nginx pueda conectarse desde su contenedor
RUN sed -i 's/^listen = .*/listen = 9000/' /etc/php83/php-fpm.d/www.conf

# 4. Descargar WP-CLI (herramienta para instalar WordPress desde la terminal)
RUN curl -o /usr/local/bin/wp \
	https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp

# 5. Copiar el script que configura WordPress al arrancar el contenedor
COPY tools/wp-installer.sh /wp-installer.sh

# 6. Carpeta donde estará WordPress (aquí se monta el volumen)
WORKDIR /var/www/html

# 7. Puerto en el que escucha PHP-FPM
EXPOSE 9000

# 8. Al arrancar, ejecutar el script
CMD ["sh", "/wp-installer.sh"]
