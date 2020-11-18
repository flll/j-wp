#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

next-lf
echo "04 Webサーバを起動させます。あらかしめサイト名を作成しておいてください"
REF=1; while [ $REF = 1 ] ;do
    site-type
    for i in {1..30};do echo -n "|";done;echo ""
done
next-lf

site-data-export

## nginxを落とす
down-nginx

docker-compose -f 01_webserver.dockercompose.yml up -d
