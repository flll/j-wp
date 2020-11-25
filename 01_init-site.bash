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
## site-type
[[ ! $REF = 2 ]] && REF=1
while [ $REF = 1 ] ;do
    site-type
done

## site-edit
REF=1; while [ $REF = 1 ] ;do
    site-edit
done

## ～証明書の作成～
#  FWの設定を忘れずに 443 80
#

if [ ! -f ~/j.d/certbot/letsencrypt/live/${DOMAINNAME}/fullchain.pem ]; then
    [[ ! -d ~/j.d/certbot ]] && mkdir -p ~/j.d/certbot
    sudo chown `echo ${USER}`:www-data ~/j.d/certbot && chmod 770 -R ~/j.d/certbot
    echo "証明書を発行します"
    echo "nginxを終了させます。nginxを起動していた場合、後ほど起動し直してください"
    docker pull -q certbot/certbot
    docker stop nginx
    docker run -it --rm --name certbot \
        -v ~/j.d/certbot/letsencrypt:/etc/letsencrypt:cached \
        -v ~/j.d/certbot/lib/letsencrypt:/var/lib/letsencrypt:cached \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -p 80:80 \
        -u  `echo ${USER}`:www-data \
            certbot/certbot certonly \
            --rsa-key-size 4096 \
            --agree-tos \
            --keep \
            --standalone \
            --staple-ocsp \
            -d "${DOMAINNAME}" \
            -m "${MAILADD}" \
                || echo -e "証明書の発行は行われませんでした。\nポート開放が行われているかご確認ください。"
    docker start nginx
fi

sudo chown -hR 82:82 ~/j.d/certbot
[[ ! -f ~/j.d/certbot/dhparam ]] && openssl dhparam -out ~/j.d/certbot/dhparam 2048
chmod 770 -R ~/j.d/certbot/*

## クロン処理を行う.
add-cron

echo "サイトと証明書の発行に成功しました: \"${SITE_NAME}\""
