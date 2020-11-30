#!/bin/bash -e
set -o pipefail
. init/func.bash

echo "!!!  サイト名を削除します  !!!"
echo "事前にバックアップを取得してください。"
echo "サイト名に基づいたlog情報、が削除されます"
echo "※02 03にてデプロイされたサービスは一度全停止します。後ほど起動し直してください"
read -p "続ける場合は y を入力してください > " accept
[[ ! $accept = [Yy] ]] && exit 0;

[[ ! $REF = 2 ]] && REF=1
while [ $REF = 1 ] ;do
    site-type
done

docker stop `docker ps -q` || :

# アプリによって作成されたデータを削除
rm -rf ~/j.d/nginx.d/${SITE_NAME}
# nginx.conf
rm  -f ~/j.d/site/conf.d/block_${SITE_NAME}.conf
# crontab.d につかうrenewシェルファイル
rm -f ~/j.d/crontab.d/${SITE_NAME}.renew
# データベース削除
rm -rf j.d/db.d/${SITE_NAME}

# 最後にサイト名のファイルを削除する
rm -rf j.d/site/${SITE_NAME}_DATA