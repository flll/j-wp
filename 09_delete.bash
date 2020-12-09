#!/bin/bash -e
set -o pipefail
cd `dirname $0`
. init/func.bash

echo "!!!  サイト名を削除します  !!!"
echo "事前にバックアップを取得してください。"
echo "サイト名に基づいたデータが削除されます。"
echo "※wordpressサービスは一度全停止します。"
echo "削除後./jj.bash 2と./jj.bash 3を再度行ってください。"
read -p "続ける場合は y を入力してください > " accept
[[ ! $accept = [Yy] ]] && exit 0; # Y以外入力時、終了

[[ ! $REF = 2 ]] && REF=1
while [ $REF = 1 ] ;do
    site-type
done


docker-compose -p ${SITE_NAME} -f ./03_webserver.dockercompose.yml down --remove-orphans || :

restart-nginx

# アプリによって作成されたデータを削除
sudo rm -rf ~/j.d/nginx.d/${SITE_NAME}
# nginx.conf
sudo rm  -f ~/j.d/site/conf.d/block_${SITE_NAME}.conf
# crontab.d につかうrenewシェルファイル
sudo rm  -f ~/j.d/crontab.d/${SITE_NAME}.renew
# データベース削除
sudo rm -rf ~/j.d/db.d/${SITE_NAME}

# 最後にサイト名のファイルを削除する
sudo rm -rf ~/j.d/site/${SITE_NAME}_DATA

echo "サイト名${SITE_NAME}の削除が完了しました"
