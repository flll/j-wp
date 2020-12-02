#!/bin/bash
## depend ../

## ～cronしょり～
function add-cron () {
    echo -n "add-cron..."
    export crontab_FOLDER=~/j.d/crontab.d
    mkdir -p ${crontab_FOLDER}
    envsubst '${DOMAINNAME} ${MAILADD}' < init/renew.bash > ${crontab_FOLDER}/${DOMAINNAME}.renew
    ln -s store/03_webserver.dockercompose.yml ${crontab_FOLDER}/03_webserver.dockercompose.yml
    #  apt-updateのコピー
    cp -f apt-update.renew ${crontab_FOLDER}/apt-update.renew
    chmod 744 ${crontab_FOLDER}/*.renew
    ## ./crontabファイルを作成する
    ## crontabにて./crontabファイルを認識させる
    cat <<-EOF > ${crontab_FOLDER}/crontab
		0 2 */3 * * \
		for files in ${crontab_FOLDER}/*.renew ; do \
		eval \${files}; \
		done
	EOF
    crontab -u ${USER} ${crontab_FOLDER}/crontab
    unset crontab_FOLDER
    echo "DONE"
}
## jj.bashのみ使用
function add-cmdcmdcmd () {
    [[ $cmdcmdcmd ]] && cmdcmdcmd+="&& " # ←add-cmdが二回以上実行されると&& をつける. ☆3
    [[ $cmdcmdcmd ]] || cmdcmdcmd="bash " #☆1
    cmdcmdcmd+="j-wp/$1 " # ☆2 の順番に、追記される [bash コマンド &&]
}
function helphelphelp () {
    cat <<- __EOF__
	    Usage $0 [options]
	    Options:
	    1       + サイト名を作成します
	            
	    2       + アプリケーションをプロビジョニング
	            ※事前にサイト名を作成してください
	    3       + ウェブサーバーをデプロイ
	            ※事前にアプリケーションをプロビジョニングしてください
	    9       + サイト名の削除
	            ※サイト名に基づいたlog/、htmlなども削除します
	    -s [サイト名]    サイト名を一つ指定でき、サイト名の入力を省くことができます
	                    サブオプションと併用することができます
	                    例) $0 -s [サイト名] 1 2 3 
	__EOF__
    exit 0;
}

function pgen () {
    cat /dev/urandom | tr -dc [A-Za-z0-9@%+] | fold -w 200 | head -n 1
}

function next-lf () {
    ## 見やすくするために改行します
    for i in {1..30};do echo "";done
}

function site-data-export () {
    ## ~/j.d/site/${SITE_NAME}_DATA から読み取り、変数にする
    #  depend site-edit() site-type()したあとの_DATAデータが必要
    export `cat ~/j.d/site/${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`
    : ${SITE_NAME:?サイト名が存在しません。もう一度やり直してください} ; REF=0 ;
}

function site-type () {
    ## 既存のサイト名の表示
    echo "現在存在するサイト:"; \
    for files in $(ls ~/j.d/site/*_DATA); do
        echo "  $files"
    done | sed -e 's/_DATA//' -e 's>^.*/site/>>'
    echo ""
    [[ ! -d ~/j.d/site ]] && mkdir ~/j.d/site

    #############################################
    echo -e "サイト名 を入力してください\n使用できる文字列は[a-z][0-9]_のみです\n例)myblog-two 例)wp1 例)wp2"
    read -p "サイト名> " SITE_NAME
        [[ -z "${SITE_NAME}" ]]              && echo -e "サイト名を入力してください\nもう一度お試しください" && REF=1 && return;
        : ${SITE_NAME,,}
        [[ "${SITE_NAME}" == *" "* ]]        && echo -e "スペースは利用不可です\nアンダーバー、ハイフンなどを代わりにご使用ください" && REF=1 && return;
        [[ "${SITE_NAME}" == *[!a-z0-9_]* ]] && echo -e "使用できる文字列a-z0-9_のみです\nもう一度入力をお願いします" && REF=1 && return;
    REF=0
    next-lf
}

function site-edit () {
    ## サイトが存在する場合、”編集” サイトが存在しない場合、”新規作成”
    [[ -f ~/j.d/site/${SITE_NAME}_DATA ]] \
        && echo -e "=== \"${SITE_NAME}\" サイトが存在しました。編集を行います===\n" \
        && site-data-export
    [[ ! -f ~/j.d/site/${SITE_NAME}_DATA ]] \
        && echo -e "=== \"${SITE_NAME}\" サイトを新規作成します===\n"

    ## ～入力項目～ ~/j.d/site/${SITE_NAME}_DATAに、
    #  "[サイト名] [domain] [メアド]"という順番の文字列で保存される
        echo "※入力をやり直したい場合ctrl+cで強制終了してください。"
        echo "ドメイン名 を入力してください 例)yahoo.jp 例)www.yahoo.co.jp"

            
        #############################################
            [[ ! -z ${DOMAINNAME} ]]        && echo -e "!!! 現在のドメイン名: ${DOMAINNAME} \n☆☆☆ 情報を変更しない場合は、そのまま ”エンターキー” を入力してください。"
        read -p "ドメイン名> " DOMAINNAME_BUFF
            [[ ! -z ${DOMAINNAME_BUFF} ]]   && DOMAINNAME=${DOMAINNAME_BUFF}
            [[ -z "${DOMAINNAME}" ]]        && echo -e "!!! ドメイン名を入力してください\nもう一度やり直してください。" && REF=1 && return;
            [[ "${DOMAINNAME}" == *" "* ]]  && echo -e "!!! スペースを含めないでください\nドット、アンダーバー、ハイフンなどを代わりにご使用ください" && REF=1 && return;


        #############################################
            [[ ! -z ${MAILADD} ]]           && echo -e "現在のメールアドレス: ${MAILADD} \n☆☆☆ 情報を変更しない場合は、そのまま ”エンターキー” を入力してください。"
        read -p "メールアドレスを入力してください > " MAILADD_BUFF
            [[ ! -z ${MAILADD_BUFF} ]]      && MAILADD=${MAILADD_BUFF}
            [[ -z "${MAILADD}" ]]           && echo "!!! メールアドレスを入力してください。もう一度やり直してください。" && REF=1 && return;
            #https://www.regular-expressions.info/email.html
            regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
            MAIL_SYNTAXERR_MESSAGE="!!! メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
            [[ ! ${MAILADD} =~ $regex ]]    && echo -e ${MAIL_SYNTAXERR_MESSAGE} && REF=1 && return;

        [[ ! -d ~/j.d/site ]] && mkdir -p ~/j.d/site
        echo -n "${SITE_NAME} ${DOMAINNAME} ${MAILADD}" > ~/j.d/site/${SITE_NAME}_DATA
        next-lf
        echo "サイト名: ${SITE_NAME} の情報を保存しました"
        REF=0
}

function restart-nginx () {
    #  プロジェクト名: web nginxをダウンさせます。
    #  nginxが起動されていた場合sleepを使って再度起動し直します
    [[ `docker ps -f name=/web-nginx$ -q` ]] \
        && echo "!!! nginxが起動しています。いちど、nginxを再起動します" \
        && echo "!!! サイト名が削除されたのち、nginxが起動します" \
        && ( # 並列処理 sleepしたあとnginxを起動する
            sleep 16; docker-compose -p web -f ./store/03_webserver.dockercompose.yml up -d \
            || echo -e "nginxが起動できませんでした。\n02が成功しているか確認してください。";
            echo nginxが起動しました
        )&
    sleep 8
}

