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

if [ ! -f ~/j.d/lego/letsencrypt/live/${DOMAINNAME}/fullchain.pem ]; then
    [[ ! -d ~/j.d/lego ]] && mkdir -p ~/j.d/lego
    echo "証明書を発行します"
    docker pull -q goacme/lego
    docker stop nginx || :
    docker run -it --rm --name lego \
        -v ~/j.d/lego:/lego:cached \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -p 443:443 \
        -u  "$(id -u ${USER}):$(id -u www-data)" \
            goacme/lego \
            --path /lego \
            --key-type ec384 \
            --accept-tos \
            --domains "${DOMAINNAME}" \
            --email "${MAILADD}" \
            --tls \
                run \
                --staple-ocsp
    docker start nginx || :
fi

[[ ! -f ~/j.d/lego/dhparam ]] && openssl dhparam -out ~/j.d/lego/dhparam 2048
chmod 770 -R ~/j.d/lego/*

## クロン処理を行う.
add-cron

echo "サイトと証明書の発行に成功しました: \"${SITE_NAME}\""
