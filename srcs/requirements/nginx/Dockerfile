FROM alpine:3.22.4

RUN apk update && apk upgrade && \
    apk add --no-cache mariadb mariadb-client bash

COPY ./conf/mariadb-conf.cnf /etc/my.cnf.d/mariadb-server.cnf

COPY ./tools/initialize.sh ./
RUN chmod +x initialize.sh

ENTRYPOINT ["./initialize.sh"]