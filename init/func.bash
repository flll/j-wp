#!/bin/bash
## depend ../

## ～cronしょり～
function add-cron () {
    if [ ! -f ./crontab ]; then #./crontabが存在しない場合、作成とcrontabの認識をさせる
    echo -n "add-cron..."
    [[ ! -d /usr/local/bin/${USER} ]] \
        && sudo mkdir -p /usr/local/bin/${USER} \
        && sudo chown `echo ${USER}` /usr/local/bin/${USER} \
        && chmod 755 /usr/local/bin/${USER}
    ln -s ${PWD}/certbot-renew.bash /usr/local/bin/${USER}/renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
    ## ./crontabファイルを作成する ※TABインデントを変更しないこと
	cat <<-EOF > ./crontab
	0 2 */3 * * /usr/local/bin/${USER}/renew.bash #深夜２時且つ３日ごとに更新を行う
	EOF
    ## crontabにて./crontabファイルを認識させる
        crontab -u ${USER} ./crontab
    echo "DONE"
    fi
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
    [[ ! -d ~/j.d/site ]] && mkdir ~/j.d/site
    aiueo=`echo ~/j.d/site/*_DATA`; [[ ! $aiueo == "~/j.d/site/*_DATA" ]] \
        && echo "現在存在するサイト:" \
        && echo `ls ~/j.d/site/*_DATA | sed -e 's/_DATA//' -e 's/^.*\/j\.d\/site\///'` \
        && for i in {1..4};do echo "";done
    #############################################
    echo -e "サイト名 を入力してください\n使用できる文字列は[a-z][0-9]_のみです\n例)myblog-two 例)wp1 例)wp2"
    read -p "サイト名> " SITE_NAME
        [[ -z "${SITE_NAME}" ]]              && echo -e "サイト名を入力してください\nもう一度お試しください" && REF=1 && return;
        SITE_NAME=${SITE_NAME,,}
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
        #############################################

        echo -n "${SITE_NAME} ${DOMAINNAME} ${MAILADD}" > ~/j.d/site/${SITE_NAME}_DATA
        next-lf
        echo "サイト名: ${SITE_NAME} の情報を保存しました"
        REF=0
}

function down-nginx () {
    docker-compose -p web -f ./store/03_webserver.dockercompose.yml down --remove-orphans || echo "startnginx"
}
