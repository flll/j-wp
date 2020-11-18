#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

next-lf
echo "04 Webサーバを起動させます。あらかしめサイト名を作成しておいてください"
sleep 3
## site-type
REF=1; while [ $REF = 1 ] ;do
    site-type
done

## nginxを落とす
down-nginx

docker-compose -f 03_webserver.dockercompose.yml up -d
