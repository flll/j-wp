#!/bin/bash -e
set -o pipefail

#ドメイン メアドが未定義の場合実行されません
export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

docker run -it --rm --name certbot \
    -v "~/certbot/letsencrypt:/etc/letsencrypt" \
    -v "~/certbot/lib/letsencrypt:/var/lib/letsencrypt" \
        certbot/certbot renew \
        -q \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
        --keep \
        --standalone \
        --http-01-port 440 \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"