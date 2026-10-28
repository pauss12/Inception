#!/bin/sh

# The main reason to create this script is to sign the certificate in a cleaner way.

# First step to sign the certificate is to create the folder where is goind to be stored.
mkdir -p /etc/nginx/ssl

# Second step is to create the certificate and the key. The certificate is self-signed, so it will not be trusted by the browser. The user will have to accept it manually.
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
	-keyout /etc/nginx/ssl/inception.key \
	-out /etc/nginx/ssl/inception.crt \
	-subj "/C=ES/O=42/L=Madrid/CN=pmendez.42.fr"


