#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash


export USER_ID=`id -u`:`id -g`

## nginxを落とす
down-nginx

docker network create web-net || echo ""

docker-compose -p web --file store/03_webserver.dockercompose.yml up
