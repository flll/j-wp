#!/bin/bash -e
set -o pipefail

## ./.${SITE_NAME}_DATA から読み取り、変数にする
export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`

docker run -it --rm --name certbot \
    -v ~/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 443:443 \
        certbot/certbot renew \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        --dry-run \
        −−preferred-challenges tls-alpn-01 \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"
