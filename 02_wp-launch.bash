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
next-lf
site-data-export


## ～コンフィグtemplate記述～
#  nginx conf
[[ ! -d ~/.site/conf.d ]] && mkdir -p ~/.site/conf.d && chmod 777 ~/.site/conf.d
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./02_template-wp-block.conf > ~/.site/conf.d/block_${SITE_NAME}.conf

export ROOTPASSWD=`pgen 100`
export DBPASSWD=`pgen 100`

down-nginx

docker-compose -f 02_wp.dockercompose.yml up -p -d ${SITE_NAME}
