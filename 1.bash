#!/bin/bash -e
set -o pipefail
cd `dirname $0`

if [ ! -f ~/.envi/DATA ]; then
    [[ ! -d ~/.envi ]] && mkdir ~/.envi
    echo "ドメイン名を入力してください。例)example.com"
    echo -e -n "サブドメインを設定している場合、含めてください。例)◯◯◯◯.example.com\n >"
    read DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1

    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ ${regex} ]] && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    echo -n "${DOMAINNAME} " > ~/.envi/DATA
    echo -n "${MAILADD}" >> ~/.envi/DATA
    echo "thank you"
fi

export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

if [ ! -f ~/nginx-persistence/lego/certificates/${DOMAINNAME}.key ] || [ ! -f ~/nginx-persistence/cert/${DOMAINNAME}.key ]; then
#cert取得専用のwebサーバの起動
#即消される
#
cat << EOF > ~/.envi/default.conf
server {
    listen      81 default_server;
    listen [::]:81 default_server;
    server_name ${DOMAINNAME};

    location /.well-known/acme-challenge/ {
    root /lego/webroot;
    }

    if (\$host != "${DOMAINNAME}") {
        return 444;
    }
}
EOF

cat << EOF > ~/.envi/nginx.conf
user nginx;
worker_processes  auto;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
    server_tokens off;
}
EOF
#nginx alpine
#証明書認証専用のnginxを起動する
#証明書認証を終わったら消される
[[ ! -d ~/.envi/lego/webroot ]] && mkdir -p ~/.envi/lego/webroot
[[ ! -d ~/.envi/lego/certificates ]] && mkdir -p ~/.envi/lego/certificates
[[ ! -d ~/.envi/lego/accounts ]] && mkdir -p ~/.envi/lego/accounts
sudo chown -R $(id -u $USER):$(id -g $USER) ~/.envi/lego
chmod 7777 -R ~/.envi/lego
echo run nginx
docker run \
    --rm \
    -p "81:81" \
    -v ~/.envi/default.conf:/etc/nginx/default.conf:ro \
    -v ~/.envi/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v ~/.envi/lego:/lego \
    -d \
        nginx:1.19.3-alpine
sleep 5
#lego alpine
#volume from:cert-nginx:/src
echo run lego
docker run \
    --rm \
    -p "80:80" \
    -v ~/.envi/lego:/lego \
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -u "$(id -u $USER):$(id -g $USER)" \
    -e LEGO_PATH="/lego" \
        goacme/lego:latest \
        --email "${MAILADD}" \
        --domains "${DOMAINNAME}" \
        --accept-tos \
        --key-type ec384 \
        --http \
            run

docker stop -t4 `docker ps -q`

docker system prune -a --force

fi

exit 0

export ROOTPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=${DOMAINNAME}

docker-compose up
