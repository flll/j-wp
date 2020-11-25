#!/bin/bash

docker stop nginx
docker run -it --rm --name certbot \
    -v ~/j.d/certbot/letsencrypt:/tmp/etc/letsencrypt:cached \
    -v ~/j.d/certbot/lib/letsencrypt:/tmp/var/lib/letsencrypt:cached \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -p 80:80 \
    -u  "$(id -u ${USER}):$(id -u www-data)" \
        certbot/certbot renew \
        --work-dir /tmp/lib/letsencrypt \
        --logs-dir /tmp/var/log/letsencrypt \
        --config-dir /tmp/etc/letsencrypt \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        --staple-ocsp
docker start nginx