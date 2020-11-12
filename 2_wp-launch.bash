#!/bin/bash -e
set -o pipefail
cd `dirname $0`

openssl dhparam -out ~/certbot/letsencrypt/live/${DOMAIN}/dhparam 2048

passleng=1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
export ROOTPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 80 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 50 | head -n 1`

docker-compose up