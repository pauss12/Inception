FROM alpine:3.23

# 1. Instalar nginx y openssl
RUN apk add --no-cache nginx openssl

# 2. Generar un certificado autofirmado para HTTPS
COPY tools/signCertificate.sh tools/signCertificate.sh
RUN chmod +x tools/signCertificate.sh && tools/signCertificate.sh

# 3. Copiar nuestra configuración y poner los puertos que llegan de .env
#    (a través de "args:" en docker-compose.yml)
COPY conf/nginx.conf /etc/nginx/http.d/default.conf
ARG PHP_PORT
ARG NGINX_PORT
RUN sed -i -e "s/fastcgi_pass  wordpress:[0-9]*;/fastcgi_pass  wordpress:${PHP_PORT};/" \
	-e "s/listen [0-9]* ssl;/listen ${NGINX_PORT} ssl;/" /etc/nginx/http.d/default.conf

# 4. NGINX_PORT (443 por defecto), para poder utilizar HTTPS (HTTP sobre TLS/SSL)
EXPOSE ${NGINX_PORT}

# 5. Arrancar nginx en primer plano como PID 1
#    "daemon off;" evita que nginx se vaya al fondo (el contenedor se cerraría)
CMD ["nginx", "-g", "daemon off;"]
