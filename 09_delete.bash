#!/bin/bash -e
set -o pipefail
. init/func.bash

echo "サイト名を削除します。"
echo "事前にバックアップを取得してください。"
echo "サイト名、基づいたlog情報、が削除されます"
read -p "続ける場合は y を入力してください > " accept
[[ ! $accept = [Yy] ]] && exit 0;

[[ ! $REF = 2 ]] && REF=1
while [ $REF = 1 ] ;do
    site-type
done

docker stop `docker ps -q` || :

# サイト名
rm  -f ~/j.d/site/${SITE_NAME}_DATA
# アプリ
rm -rf ~/j.d/nginx.d/${SITE_NAME}
# nginx.conf
rm  -f ~/j.d/site/conf.d/block_${SITE_NAME}.conf
