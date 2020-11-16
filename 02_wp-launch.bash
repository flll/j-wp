#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

##既存のサイト名の表示
next-lf
REF=1; while [ $REF = 1 ] ;do
    site-type
    for i in {1..30};do echo -n "|";done;echo ""
done
next-lf

config-add-fastcgi=$(envsubst '${SITE_NAME}' < EOF >> cat
location ~ \.php$ {
    fastcgi_pass ${SITE_NAME}:9000;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
  }
EOF
) && \
    sed -e 's/^#this-php-block/${config-add-fastcgi}/g' \
    ~/.site/conf.d/block_${SITE_NAME}.conf

export ROOTPASSWD=`pgen 100`
export DBPASSWD=`pgen 100`

down-nginx

docker-compose -f 02_serverside.dockercompose.yml up -p ${SITE_NAME}
