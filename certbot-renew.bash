#!/bin/bash -e
set -o pipefail

#ドメイン メアドが未定義の場合実行されません
export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

docker run -it --rm --name certbot \
    -v "~/certbot/letsencrypt:/etc/letsencrypt" \
    -v "~/certbot/lib/letsencrypt:/var/lib/letsencrypt" \
    -p 80:80 \
        certbot/certbot renew \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
        --keep \
        --standalone \
        --dry-run \
        −−preferred-challenges tls-alpn-01 \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"