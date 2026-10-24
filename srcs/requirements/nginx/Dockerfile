FROM alpine:3.23

# 1. Instalar nginx y openssl
RUN apk add --no-cache nginx openssl

# 2. Generar un certificado autofirmado para HTTPS
COPY tools/signCertificate.sh tools/signCertificate.sh
RUN chmod +x tools/signCertificate.sh && tools/signCertificate.sh

# 3. Copiar nuestra configuración
COPY conf/nginx.conf /etc/nginx/http.d/default.conf

# 4. 443, para poder utilizar HTTPS (HTTP sobre TLS/SSL)
EXPOSE 443

# 5. Arrancar nginx en primer plano como PID 1
#    "daemon off;" evita que nginx se vaya al fondo (el contenedor se cerraría)
CMD ["nginx", "-g", "daemon off;"]
