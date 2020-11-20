#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

## 
#  サイト名とは複数のwebページを同じインスタンス、IPアドレスで、
#  別々のwebサイトを表示させる”任意機能”です
##


next-lf
echo "＝＝＝ 01 サイト名と証明書を発行します ＝＝＝"
echo "サイト名とは、https://wp1.lll.fish や https://wp2.lll.fish などの"
echo "一つのサーバーで複数のドメイン、ウェブサイトを運営"
echo "することができます。かならず一つ以上作成してください"
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
    echo "nginxを終了させます。証明書の作成が完了したら"
    echo "忘れずに03_webを起動させてください"
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

sudo chown -hR `id -u`:www-data ~/certbot
chmod 0770 -R ~/certbot/*
[[ ! -f ~/certbot/dhparam ]] && openssl dhparam -out ~/certbot/dhparam 2048


## クロン処理を行う.
add-cron

echo "サイトと証明書の発行に成功しました: \"${SITE_NAME}\""
