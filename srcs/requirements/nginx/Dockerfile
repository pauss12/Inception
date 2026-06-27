FROM nginx:stable-alpine

RUN apk update && apk upgrade || true

# Copy nginx configuration files (expects conf/ to contain site configs)
COPY ./conf/ /etc/nginx/conf.d/

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]