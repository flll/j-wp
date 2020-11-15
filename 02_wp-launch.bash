#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

##既存のサイト名の表示
next-lf
REF=1; while [ $REF = 1 ] ;do
    site-type
    for i in {1..30};do echo -n "|";done;echo ""
done
next-lf

export ROOTPASSWD=`pgen 100`
export DBPASSWD=`pgen 100`

docker-compose -f 02_serverside.dockercompose.yml up -p ${SITE_NAME}
