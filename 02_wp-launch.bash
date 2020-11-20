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
[[ ! -d ~/.site/conf.d ]] && mkdir -p ~/.site/conf.d && chmod 770 ~/.site/conf.d
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./store/02_template-wp-block.conf > ~/.site/conf.d/block_${SITE_NAME}.conf
echo 0
[[ ! -d ~/nginx.d ]] && mkdir ~/nginx.d && sudo chown -hR `id -u`:www-data ~/nginx.d
echo 1
[[ ! -d ~/.site/sec ]] && mkdir ~/.site/sec && chmod 700 ~/.site/sec
echo 2
[[ ! -f ~/.site/sec/db_root_pass.txt ]] && pgen 200 > ~/.site/sec/db_root_pass.txt
echo 3
[[ ! -f ~/.site/sec/db_wp_pass.txt ]] && pgen 200 > ~/.site/sec/db_wp_pass.txt
echo b
export ROOTPASSWD=`cat ~/.site/sec/db_root_pass.txt`
export DBPASSWD=`cat ~/.site/sec/db_wp_pass.txt`
echo a
down-nginx
echo a
docker network create web-net || echo ""
docker network create wp-db-net || echo ""
docker-compose -p ${SITE_NAME} --file store/02_wp.dockercompose.yml up
echo end