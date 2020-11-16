#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

export IDUG="`id -u`:`id -g`"
## 
#  サイト名とは複数のwebページを同じインスタンス、IPアドレスで、
#  別々のwebサイトを表示させる”任意機能”です
#  サイト名はドメインホスト別で複数作成することができます。
#  SSLの証明書はドメインホスト別で作成を行います。
#  サイト名を複数作成する場合、
#  ※サイトの作成、編集を行った場合Nginxを再起動してください。
##

## site-type
next-lf
REF=1; while [ $REF = 1 ] ;do
    site-type
    for i in {1..30};do echo -n "|";done;echo ""
done
next-lf

## site-edit
REF=1; while [ $REF = 1 ] ;do
    site-edit
    for i in {1..30};do echo -n "|";done;echo ""
done
next-lf

site-data-export

## ～証明書の作成～
#  FWの設定を忘れずに 443 80
#

if [ ! -f ~/certbot/letsencrypt/live/${DOMAINNAME}/fullchain.pem ]; then
    docker pull -q certbot/certbot
    docker stop `docker ps -f name=nginx -q` 2>/dev/null || echo "nginxは起動していません。続行します" # nginxコンテナが存在しない場合stopは行えない
    docker run -it --rm --name certbot \
        -v ~/certbot/letsencrypt:/etc/letsencrypt:cached \
        -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt:cached \
        -p 80:80 \
            certbot/certbot certonly \
            --rsa-key-size 4096 \
            --agree-tos \
            --keep \
            --standalone \
            -d "${DOMAINNAME}" \
            -m "${MAILADD}" \
                || echo -e "証明書の発行は行われませんでした。\n証明書が新しいか、ポート開放がおこわなれていないか。ご確認ください。"
fi

sudo chown -hR $IDUG ~/certbot
chmod 0700 -R ~/certbot/*
[[ ! -f ~/certbot/dhparam ]] && openssl dhparam -out ~/certbot/dhparam 2048

## ～コンフィグtemplate記述～
#  nginx conf
[[ ! -d ~/.site/conf.d ]] && mkdir -p ~/.site/conf.d && chmod 777 ~/.site/conf.d
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./template-server-block.conf > ~/.site/conf.d/block_${SITE_NAME}.conf

## 必要なフォルダを作成
[[ ! -d ~/log/${SITE_NAME} ]] \
    && mkdir -p ~/log/${SITE_NAME} \
    && sudo chown $IDUG \
    && chmod 766 -R ~/log/*
[[ ! -f ~/log/${SITE_NAME}/nginx-access.log ]] || [[ ! -f ~/log/${SITE_NAME}/nginx-error.log ]] && \
        touch ~/log/${SITE_NAME}/nginx-error.log ~/log/${SITE_NAME}/nginx-access.log && chmod 766 -R ~/log/*

## クロン処理を行う.
add-cron

## nginxを落とす
down-nginx

docker-compose -f 01_webserver.dockercompose.yml up
