#!/bin/bash -e
set -o pipefail
cd `dirname $0`


## 
# サイト名とは複数のwebページを同じインスタンス、IPアドレスで、
# 別々のwebサイトを表示させる”任意機能”です
# サイト名はドメインホスト別で複数作成することができます。
# SSLの証明書はドメインホスト別で作成を行います。
# サイト名を複数作成する場合、
# ※サイトの作成、編集を行った場合Nginxを再起動してください。
#
##既存のサイト名の表示
for i in {1..20};do echo "";done
aiueo=`echo .*_DATA`; [[ ! $aiueo == ".*_DATA" ]] \
    && echo "現在存在するサイト:" \
    && echo `ls .*_DATA | sed -e 's/_DATA//' -e 's/^[.]//'` \
    && for i in {1..2};do echo "";done

#############################################
echo "半角英数字のスペースなしでお願いします。"
echo -e "サイト名 を入力してください\n使用できる文字列は[a-z][0-9]_-.のみです\n例)wordpress 例)myblog 例)lll_fish 例)wp_lll_fish"
read -p "サイト名> " SITE_NAME
SITE_NAME=${SITE_NAME,,}
[[ -z "${SITE_NAME}" ]]               && echo -e "サイト名を入力してください\nもう一度お試しください" && exit 1
[[ "${SITE_NAME}" == *" "* ]]         && echo -e "スペースは利用不可です\nアンダーバー、ハイフンなどを代わりにご使用ください" && exit 1
[[ "${SITE_NAME}" == *[!a-z0-9_-]* ]] && echo -e "使用できる文字列a-z0-9_-のみです\nもう一度入力をお願いします" && exit 1
for i in {1..20};do echo "";done
## サイトが存在する場合、”編集”
#  サイトが存在しない場合、”新規作成”
[[ -f ./.${SITE_NAME}_DATA ]]       && echo -e "===\"${SITE_NAME}\" サイトが存在しました。編集を行います===\n" \
    && export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")` \

[[ ! -f ./.${SITE_NAME}_DATA ]]     && echo -e "===\"${SITE_NAME}\" サイトを新規作成します===\n"

## ～入力項目～ ./.${SITE_NAME}_DATAに、
#  "[サイト名] [domain] [メアド]"という順番の文字列で保存される
    echo "入力をやり直したい場合ctrl+cで強制終了してください。"
    echo "ドメイン名 を入力してください 例)yahoo.jp 例)www.yahoo.co.jp"
    [[ ! -z ${DOMAINNAME} ]]        && echo -e "現在のドメイン名: ${DOMAINNAME} \nそのままエンターキーを入力すると変更されません。"
    read -p "ドメイン名> " DOMAINNAME_BUFF
    [[ ! -z ${DOMAINNAME_BUFF} ]]   && DOMAINNAME=${DOMAINNAME_BUFF} && echo "設定を変更しました"
    [[ -z "${DOMAINNAME}" ]]        && echo -e "ドメイン名を入力してください\nもう一度やり直してください。" && exit 1
    [[ "${DOMAINNAME}" == *" "* ]]  && echo -e "スペースを含めないでください\nドット、アンダーバー、ハイフンなどを代わりにご使用ください" && exit 1
    #############################################
    [[ ! -z ${MAILADD} ]]           && echo -e "現在のメールアドレス: ${MAILADD} \nそのままエンターキーを入力すると変更されません。"
    read -p "メールアドレスを入力してください > " MAILADD_BUFF
    [[ ! -z ${MAILADD_BUFF} ]]      && DOMAINNAME=${MAILADD_BUFF} && echo "設定を変更しました"
    [[ -z "${MAILADD}" ]]           && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ $regex ]]    && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    #############################################
    echo -n "${SITE_NAME} ${DOMAINNAME} ${MAILADD}" > ./.${SITE_NAME}_DATA
    echo "サイト名: ${SITE_NAME} の情報を保存しました"

## ./.${SITE_NAME}_DATA から読み取り、変数にする
export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`

## ～証明書の作成～
#  FWの設定を忘れずに 443
#  
docker pull certbot/certbot
docker stop `docker ps -f name=nginx -q` || echo ""
docker run -it --rm --name certbot \
    -v ~/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 80:80 \
        certbot/certbot certonly \
        --rsa-key-size 4096 \
        --agree-tos \
        --keep \
        --standalone \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"

sudo chown `echo $USER` -R ~/certbot
openssl dhparam -out ~/certbot/letsencrypt/live/${DOMAINNAME}/dhparam 2048

## ～コンフィグtemplate記述～
#  nginx conf
envsubst '${SITE_NAME} ${DOMAINNAME}' \
        < ./server-block.conf.temp > ./conf.d/block_${SITE_NAME}.conf

exit 0

## ～cronしょり～
if [ ! -f ./crontab ]; then #./crontabが存在しない場合、作成とcrontabの認識をさせる
    ln -s ./certbot-renew.bash /usr/local/bin/renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
## ./crontabファイルを作成する
cat << EOF > ./crontab
0 2 */3 * * /usr/local/bin/renew.bash #深夜２時且つ３日ごとに更新を行う
EOF
## crontabにて./crontabファイルを認識させる
    crontab -u $USER ./crontab
fi


echo "ウェルダン"