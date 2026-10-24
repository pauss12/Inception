FROM alpine:3.23

# 1. Instalar nginx y openssl (openssl sirve para crear el certificado TLS)
RUN apk add --no-cache nginx openssl

# 2. Crear un certificado autofirmado para HTTPS
#    -x509: certificado autofirmado (no lo firma ninguna autoridad)
#    -nodes: la clave privada no lleva contraseña
#    -subj: datos del certificado; CN = nuestro dominio
RUN mkdir -p /etc/nginx/ssl && \
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/O=42/CN=pmendez-.42.fr"

# 3. Copiar nuestra configuración (sustituye a la que trae Alpine por defecto)
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# 4. Puerto HTTPS: la única entrada a toda la infraestructura
EXPOSE 443

# 5. Arrancar nginx en primer plano como PID 1
#    "daemon off;" evita que nginx se vaya al fondo (el contenedor se cerraría)
CMD ["nginx", "-g", "daemon off;"]
