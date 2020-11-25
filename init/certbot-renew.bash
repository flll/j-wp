#!/bin/bash -e
set -o pipefail

## ~/j.d/site/${SITE_NAME}_DATA から読み取り、変数にする
export `cat ~/j.d/site/${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`

docker run -it --rm --name certbot \
    -v ~/j.d/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/j.d/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 80:80 \
        certbot/certbot renew \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        --staple-ocsp \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"
