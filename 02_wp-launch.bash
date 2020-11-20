#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

##既存のサイト名の表示
next-lf
echo "＝＝＝ 02 ワードプレスとデータベースを起動します ＝＝＝"
REF=1; while [ $REF = 1 ] ;do
    site-type
    for i in {1..30};do echo -n "|";done;echo ""
done
site-data-export


## ～コンフィグtemplate記述～
#  nginx conf
[[ ! -d ~/.site/conf.d ]] && mkdir -p ~/.site/conf.d && chmod 777 ~/.site/conf.d
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./store/02_template-wp-block.conf > ~/.site/conf.d/block_${SITE_NAME}.conf

[[ ! -d ~/nginx.d ]] && mkdir ~/nginx.d && chown www-data:www-data ~/nginx.d

# `pgen 100`
export ROOTPASSWD=aaa
export DBPASSWD=aaa

down-nginx

docker network create web-net || echo ""
docker network create wp-db-net || echo ""
docker-compose -p ${SITE_NAME} --file store/02_wp.dockercompose.yml up
