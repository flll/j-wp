#!/bin/bash -e
set -o pipefail
cd `dirname $0`

echo サイト名に基づいてwordpressを起動させます。
read -p "サイト名> " SITE_NAME
## ./.${SITE_NAME}_DATA から読み取り、変数にする
export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`


passleng=1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
export ROOTPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 80 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 50 | head -n 1`

docker-compose -f 02_serverside.dockercompose.yml up -p ${SITE_NAME}