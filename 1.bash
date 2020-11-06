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

if [ ! -f ~/nginx-persistence/cert/${DOMAINNAME}.key ] || [ ! -f ~/nginx-persistence/cert/${DOMAINNAME}.key ]; then
#cert取得専用のwebサーバの起動
#即消される
#
cat << EOF > ./cert-nginx.conf
worker_processes auto;
server {
    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  ${DOMAINNAME};
    root         /src;
}
EOF
#nginx alpine
#証明書認証専用のnginxを起動する
#証明書認証を終わったら消される
docker run \
    --rm \
    --name cert-nginx \
    -p "80:80" \
    -v /src \
    -v ./cert-nginx.conf:/etc/nginx/nginx.conf:ro \
    -d \
        nginx:1.19.3-alpine

sleep 3
#lego alpine 
#volume from:cert-nginx:/src
docker run \
    --rm \
    -v ~/nginx-persistence/lego:/lego \
    --volumes-from cert-nginx\
    -e LEGO_PATH="/lego" \
        goacme/lego:latest \
        --email "${MAILADD}" \
        --domains "${DOMAINNAME}" \
        --accept-tos \
        --key-type ec384 \
        --http \
        --http.webroot /src \
        --filename "server" \
            run \
            --must-staple

docker stop `docker ps -q -a`

docker system prune --force

fi

exit 0

export ROOTPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=${DOMAINNAME}

docker-compose up
