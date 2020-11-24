#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

# チケットセッション
openssl rand 48 > ~/j.d/certbot/tls_session_ticket.key

## nginxを落とす
down-nginx

docker network create web-net || :

docker-compose -p web --file store/03_webserver.dockercompose.yml up
