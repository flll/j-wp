#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

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
    for i in {1..10};do echo -e "|";done;echo ""
done
next-lf

## site-edit
REF=1; while [ $REF = 1 ] ;do
    site-edit
    for i in {1..10};do echo -e "|";done;echo ""
done
next-lf

site-data-export

## ～証明書の作成～
#  FWの設定を忘れずに 443 80
#  
docker pull certbot/certbot
docker stop `docker ps -f name=nginx -q` || echo "" # nginxコンテナが存在しない場合stopは行えない
docker run -it --rm --name certbot \
    -v ~/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 80:80 \
        certbot/certbot certonly \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"

sudo chown `echo $USER` -R ~/certbot
openssl dhparam -out ~/certbot/letsencrypt/live/${DOMAINNAME}/dhparam 2048

## ～コンフィグtemplate記述～
#  nginx conf
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./server-block.conf.temp > ./conf.d/block_${SITE_NAME}.conf

exit 0

# クロン処理を行う.
add-cron


echo "ウェルダン"