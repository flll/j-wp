#!/bin/bash

docker stop nginx
docker run -it --rm --name certbot \
    -v ~/j.d/certbot/letsencrypt:/a/etc/letsencrypt:cached \
    -v ~/j.d/certbot/lib/letsencrypt:/a/var/lib/letsencrypt:cached \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -p 80:80 \
    -u  "$(id -u ${USER}):$(id -u www-data)" \
        certbot/certbot renew \
        --work-dir /a/lib/letsencrypt \
        --logs-dir /a/var/log/letsencrypt \
        --config-dir /a/etc/letsencrypt \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        --staple-ocsp
docker start nginx