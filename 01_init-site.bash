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


next-lf
echo "01 サイト名と証明書を発行します。"
sleep 3
## site-type
REF=1; while [ $REF = 1 ] ;do
    site-type
done

## site-edit
REF=1; while [ $REF = 1 ] ;do
    site-edit
done

## ～証明書の作成～
#  FWの設定を忘れずに 443 80
#

if [ ! -f ~/certbot/letsencrypt/live/${DOMAINNAME}/fullchain.pem ]; then
    echo "証明書を発行します"
    echo "nginxを終了させます。忘れずに03を起動させておいてください。"
    sleep 3
    docker pull -q certbot/certbot
    down-nginx
    docker run -it --rm --name certbot \
        -v ~/certbot/letsencrypt:/etc/letsencrypt:cached \
        -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt:cached \
        -p 80:80 \
            certbot/certbot certonly \
            --rsa-key-size 4096 \
            --agree-tos \
            --keep \
            --standalone \
            --staple-ocsp \
            -d "${DOMAINNAME}" \
            -m "${MAILADD}" \
                || echo -e "証明書の発行は行われませんでした。\n証明書が新しいか、ポート開放がおこわなれていないか。ご確認ください。"
fi

sudo chown -hR `id -u`:`id -g` ~/certbot
chmod 0700 -R ~/certbot/*
[[ ! -f ~/certbot/dhparam ]] && openssl dhparam -out ~/certbot/dhparam 2048

## 必要なフォルダを作成  必要かどうか不明
[[ ! -d ~/log/${SITE_NAME} ]] \
    && mkdir -p ~/log/${SITE_NAME} \
    && sudo chown `id -u`:`id -g` \
    && chmod 777 -R ~/log/*

## クロン処理を行う.
add-cron

echo "サイトの作成に成功しました: \"${SITE_NAME}\""
