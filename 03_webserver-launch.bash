#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

## nginxを落とす
down-nginx

docker network create web-net

docker-compose -p web --file ./store/03_webserver.dockercompose.yml up
