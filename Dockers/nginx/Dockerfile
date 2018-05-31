FROM nginx:1.13.12

LABEL maintainer="info@wearespindle.com"

COPY nginx.conf /etc/nginx/nginx.conf

COPY mycert.pem /etc/ssl/certs/mycert.pem
COPY mykey.key /etc/ssl/private/mykey.key
