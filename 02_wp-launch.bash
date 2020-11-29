#!/bin/bash -e
set -o pipefail
cd `dirname $0`
. init/func.bash

##既存のサイト名の表示
echo "＝＝＝ 02 ワードプレスとデータベースを起動します ＝＝＝"

## サイト名が存在しない場合は02を実行させない
#  サイト名が複数存在する場合はそのサイト名すべてをwpアプリでデプロイさせるかを確認させる
[[ $(ls ~/j.d/site/*_DATA | head | wc -l) ]] && echo "サイト名が存在しません./jj.bash 1 にてサイト名を作成してください。" && exit 0;
## サイト名が複数存在する場合、loopを使って複数のサイトを作成します
if [ ! 1 = $(ls ~/j.d/site/*_DATA | head | wc -l) ]
    echo "サイト名が複数存在します。ほか全てのサイト名をワードプレスで起動しますか？[Y/n]"
    read -p "\"Y\"以外を入力すると、単一での起動となります。" kyodaku
    [[ $kyodaku != [Yy] ]] && return;

    for files in ${crontab_FOLDER}/*.renew ; do \
        SITE_NAME=`echo $files | sed -e 's/_DATA//' -e 's>^.*/site/>>'`
        site-data-export    # *で渡されたサイトファイルに基づいてサイトの中身をexportする
        init-wp-function
        ## default.confが存在すれば init-nginx-conf を実行させない
        [[ ! -f ~/j.d/site/conf.d/default.conf ]] && init-nginx-conf
        wp-deploy           # docker-composeを起動させる
	done
    exit 0
fi

[[ $REF = 2 ]] || REF=1
while [ $REF = 1 ] ;do
    site-type
done
#  ドメインが書かれていない場合site-data-export
[[ ! ${DOMAINNAME} ]] && site-data-export

site-data-export    # *で渡されたサイトファイルに基づいてサイトの中身をexportする
init-wp-function
## default.confが存在すれば init-nginx-conf を実行させない
[[ ! -f ~/j.d/site/conf.d/default.conf ]] && init-nginx-conf
wp-deploy           # docker-composeを起動させる



#######################################################
##### #    #  #    #   #### ####### ###   ####   #    #
#     #    #  ##   #  ##       #     #   ##  ##  ##   #
#     #    #  ###  #  #        #     #   #    #  ###  #
####  #    #  # #  #  #        #     #   #    #  # #  #
#     #    #  #  # #  #        #     #  ##    #  #  # #
#     #    #  #  ###  #        #     #   #    #  #  ###
#     ##  #   #   ##  ##       #     #   ##  #   #   ##
#      ####   #    #   ####    #    ###   ###    #    #
#######################################################

## ～コンフィグtemplate記述～
#  nginx conf
function init-wp-function() {
    #  confディレクトリを作成
    [[ ! -d ~/j.d/site/conf.d ]] && mkdir -p ~/j.d/site/conf.d && chmod 770 ~/j.d/site/conf.d
    #  conf.d ディレクトリにブロック.confを追加
    envsubst '${SITE_NAME} ${DOMAINNAME}' \
            < ./store/02_template-wp-block.conf > ~/j.d/site/conf.d/block_${SITE_NAME}.conf
    #  ログファイルを保管する用のディレクトリを追加 nginxが使う
    [[ ! -d ~/j.d/log/${SITE_NAME} ]] \
        && mkdir -p ~/j.d/log/${SITE_NAME} \
        && sudo chown -hR 82:82 ~/j.d/log/
    ## 必要なフォルダを作成 nginx.d
    [[ ! -d ~/j.d/nginx.d/${SITE_NAME} ]] \
        && mkdir -p ~/j.d/nginx.d/${SITE_NAME} \
        && sudo chown -hR 82:82 ~/j.d/nginx.d
    #  nginx.dディレクトリの作成 wp本体が入ります
    [[ ! -d ~/j.d/nginx.d ]] \
        && mkdir ~/j.d/nginx.d \
        && sudo chown -hR 82:82 ~/j.d/nginx.d
    #  site/secディレクトリの作成 PASS系のファイルが入ります
    [[ ! -d ~/j.d/site/sec ]] \
        && mkdir ~/j.d/site/sec \
        && chmod 770 ~/j.d/site/sec
    #  PASS系の変数定義 DB通信に使う用のパスワードを保存＆取り込みを行います
    [[ ! -f ~/j.d/site/sec/db_root_pass.txt ]] \
        && pgen > ~/j.d/site/sec/db_root_pass.txt
    [[ ! -f ~/j.d/site/sec/db_wp_pass.txt ]]   \
        && pgen > ~/j.d/site/sec/db_wp_pass.txt
    [[ $ROOTPASSWD ]] || export ROOTPASSWD=`cat ~/j.d/site/sec/db_root_pass.txt`
    [[ $DBPASSWD ]]   || export DBPASSWD=`cat ~/j.d/site/sec/db_wp_pass.txt`
}

function init-nginx-conf () {
    cat <<-'EOF' > ~/j.d/site/conf.d/default.conf
    server {
        listen       80 default_server;
        server_name  _;
        return       444;
	}
	EOF
}

function wp-deploy () {
    # wpコンテナ(${SITE_NAME}_wp)が存在する場合、return を返す
    [[ $(docker ps -f name=${SITE_NAME}_wp -q ) ]] \
        && echo "!!! ${SITE_NAME}_wpは実行されています。続行しますか？[Y/n]" \
        && read -p "\"Y\"を入力すると無視します > " kyodaku \
        && [[ $kyodaku != [Yy] ]] && return;
    docker stop nginx
    [[ `docker network ls -q -f name=web-net` ]]   || docker network create web-net
    [[ `docker network ls -q -f name=wp-db-net` ]] || docker network create wp-db-net
    docker-compose -p ${SITE_NAME} --file store/02_wp.dockercompose.yml up -d
    docker start nginx
}
