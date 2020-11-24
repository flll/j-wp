#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

##既存のサイト名の表示
next-lf
echo "＝＝＝ 02 ワードプレスとデータベースを起動します ＝＝＝"
[[ $REF = 2 ]] || REF=1
while [ $REF = 1 ] ;do
    site-type
done

## ～コンフィグtemplate記述～
#  nginx conf
[[ ! -d ~/j.d/site_name/conf.d ]] && mkdir -p ~/j.d/site_name/conf.d && chmod 770 ~/j.d/site_name/conf.d
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./store/02_template-wp-block.conf > ~/j.d/site_name/conf.d/block_${SITE_NAME}.conf
envsubst '${SITE_NAME}' \
        < ./store/php.ini > ~/j.d/site_name/conf.d/${SITE_NAME}.php.ini
envsubst '${SITE_NAME}' \
        < ./store/php-fpm.ini > ~/j.d/site_name/conf.d/${SITE_NAME}.php-fpm.ini


cat << 'EOF' > ~/j.d/site_name/conf.d/default.conf
server {
    listen       80 default_server;
    server_name  _;
    return       444;
}
EOF

## 必要なフォルダを作成 log
[[ ! -d ~/j.d/log/${SITE_NAME} ]] \
    && mkdir -p ~/j.d/log/${SITE_NAME} \
    && sudo chown -hR 82:82 ~/j.d/log/

## 必要なフォルダを作成 nginx.d
[[ ! -d ~/j.d/nginx.d/${SITE_NAME} ]] \
    && mkdir -p ~/j.d/nginx.d/${SITE_NAME} \
    && sudo chown -hR 82:82 ~/j.d/nginx.d

[[ ! -d ~/j.d/nginx.d ]] && mkdir ~/j.d/nginx.d && sudo chown -hR 82:82 ~/j.d/nginx.d
[[ ! -d ~/j.d/site_name/sec ]] && mkdir ~/j.d/site_name/sec && chmod 770 ~/j.d/site_name/sec
[[ ! -f ~/j.d/site_name/sec/db_root_pass.txt ]] && pgen > ~/j.d/site_name/sec/db_root_pass.txt
[[ ! -f ~/j.d/site_name/sec/db_wp_pass.txt ]] && pgen > ~/j.d/site_name/sec/db_wp_pass.txt
export ROOTPASSWD=`cat ~/j.d/site_name/sec/db_root_pass.txt`
export DBPASSWD=`cat ~/j.d/site_name/sec/db_wp_pass.txt`

down-nginx
docker network create web-net || echo ""
docker network create wp-db-net || echo ""
docker-compose -p ${SITE_NAME} --file store/02_wp.dockercompose.yml up