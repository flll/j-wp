#!/bin/bash -e
set -o pipefail
cd `dirname $0`

. init/func.bash

## nginxを落とす
down-nginx

docker-compose --project-name web --file ./store/03_webserver.dockercompose.yml up
