#!/bin/bash -e
set -o pipefail

#メールアドレス　ドメインが未定義の場合実行されません
export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

docker run \
    --rm \
    -v ~/lego-persistence:/lego \
    -p "440:440" \
    -e LEGO_PATH="/lego" \
        goacme/lego:latest \
        --email "${MAILADD}" \
        --domains "${DOMAINNAME}" \
        --accept-tos \
        --key-type ec384 \
        --tls \
        --tls.port :440 \
            renew \
            --must-staple \
            --days 75
