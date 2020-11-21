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
envsubst '${SITE_NAME}' \
        < ./store/php.ini > ~/.site/conf.d/${SITE_NAME}.php.ini

cat << 'EOF' > ~/.site/conf.d/default.conf
server {
    listen       80 default_server;
    server_name  _;
    return       444;
}
EOF

## 必要なフォルダを作成 log
[[ ! -d ~/log/${SITE_NAME} ]] \
    && mkdir -p ~/log/${SITE_NAME} \
    && sudo chown -hR 82:82 ~/log/

## 必要なフォルダを作成 nginx.d
[[ ! -d ~/nginx.d/wp1/src ]] \
    && mkdir -p ~/nginx.d/wp1/src \
    && sudo chown -hR 82:82 ~/nginx.d

[[ ! -d ~/nginx.d ]] && mkdir ~/nginx.d && sudo chown -hR 82:82 ~/nginx.d
[[ ! -d ~/.site/sec ]] && mkdir ~/.site/sec && chmod 770 ~/.site/sec
[[ ! -f ~/.site/sec/db_root_pass.txt ]] && pgen > ~/.site/sec/db_root_pass.txt
[[ ! -f ~/.site/sec/db_wp_pass.txt ]] && pgen > ~/.site/sec/db_wp_pass.txt
export ROOTPASSWD=`cat ~/.site/sec/db_root_pass.txt`
export DBPASSWD=`cat ~/.site/sec/db_wp_pass.txt`

down-nginx
docker network create web-net || echo ""
docker network create wp-db-net || echo ""
docker-compose -p ${SITE_NAME} --file store/02_wp.dockercompose.yml up