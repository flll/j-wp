#!/bin/bash -e
set -o pipefail
cd `dirname $0`
. init/func.bash

# チケットセッション
openssl rand 48 > ~/j.d/lego/tls_session_ticket.key

## nginxを落とす
[[ `docker ps -f name=/web-nginx$ -q` ]] && docker-compose -p web -f ./store/03_webserver.dockercompose.yml down --remove-orphans

docker network create web-net || :

docker-compose -p web --file store/03_webserver.dockercompose.yml up \
    || echo -e "nginxが起動できませんでした。\n02が成功しているか確認してください。" && docker ps
