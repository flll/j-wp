#!/bin/bash

docker stop nginx
docker run -it --rm --name certbot \
    -v ~/j.d/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/j.d/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 80:80 \
        certbot/certbot renew \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        --staple-ocsp
docker start nginx