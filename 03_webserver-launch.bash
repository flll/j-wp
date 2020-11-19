#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash


## 必要なフォルダを作成  必要かどうか不明
[[ ! -d ~/log/${SITE_NAME} ]] \
    && mkdir -p ~/log/${SITE_NAME} \
    && sudo chown -hR `id -u`:www-data ~/log/

## nginxを落とす
down-nginx

docker network create web-net || echo ""

docker-compose -p web --file store/03_webserver.dockercompose.yml up
