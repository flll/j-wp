#!/bin/bash

cd `dirname $0`

sleep 10
# nginxが起動していないと証明書の更新を行われない
[[ `docker ps -f name=/web-nginx$ -f status=running -q` ]] \
        || exit 1

#####################################
# シンボリックにて用意されたymlを使用します
# storeで指定しないでください
docker-compose -p web -f ./03_webserver.dockercompose.yml down --remove-orphans

#チケットセッション
openssl rand 48 > ~/j.d/lego/tls_session_ticket.key

    docker run -it --rm --name lego \
        -v ~/j.d/lego:/lego:cached \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -p 443:443 \
            goacme/lego \
            --path /lego \
            --key-type ec384 \
            --accept-tos \
            --tls \
            --domains "${DOMAINNAME}" \
            --email "${MAILADD}" \
                renew \
                --must-staple \
                --days 75

docker-compose -p web -f ./03_webserver.dockercompose.yml up -d
