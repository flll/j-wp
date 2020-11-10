#!/bin/bash -e
set -o pipefail

#ドメイン メアドが未定義の場合実行されません
export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

docker run -it --rm --name certbot \
    -v "~/certbot-persistence/letsencrypt:/etc/letsencrypt" \
    -v "~/certbot-persistence/lib/letsencrypt:/var/lib/letsencrypt" \
        certbot/certbot \
        -q \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
            renew \
            --keep \
            --standalone \
            --http-01-port 440
