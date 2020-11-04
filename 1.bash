#!/bin/bash -e
set -o pipefail
cd `dirname $0`

if [ ! -f ~/.envi/DATA ]; then
    [[ ! -d ~/.envi ]] && mkdir ~/.envi
    read -p "ドメイン名を入力してください > " DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1
    echo -n "${DOMAINNAME} " > ~/.envi/DATA

    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    [[ ! ${MAILADD} =~ ${regex} ]] && echo "メールアドレスの構文が間違っています。" && echo "ドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください" && exit 1
    echo -n ${MAILADD} >> ~/.envi/DATA
fi

export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

if [ ! -f ~/nginx-persistence/cert/server.key ]; then
docker run \
    --rm \
    -p "80:80" \
    -v ~/nginx-persistence/cert:/cert \
    -e LEGO_PATH="/cert" \
    goacme/lego \
        --email "$MAILADD" \
        --domains "$DOMAINNAME" \
        --accept-tos \
        --key-type ec384 \
        --http \
        --filename "server" \
        run \
            --must-staple

fi

exit 0

export ROOTPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=$DOMAINNAME

docker-compose up
