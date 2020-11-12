#!/bin/bash -e
set -o pipefail
cd `dirname $0`


## 
# サイト名とは複数のwebページを同じIPで、別々のwebサイトを表示させる”任意機能”です
# サイト名は複数作成することができます。
# サイト名を複数作成することによってNginxのvirtualhost
# SSLの証明書はホスト別で作成を行います。
# サイト名を複数作成する場合、
# ※サイトの作成、編集を行った場合Nginxを再起動してください。
#
#############################################
echo "半角英数字のスペースなしでお願いします。"
echo "サイト名 を入力してください 例)wordpress 例)myblog"
read -p "サイト名> " SITE_NAME
ls *_DATA #←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←未実装

## サイトが存在する場合、”編集”
# サイトが存在しない場合、”新規作成”
[[ -f ./.${SITE_NAME}_DATA ]]   && echo -e "===サイトが存在しました。編集を行います===\n"
[[ ! -f ./.${SITE_NAME}_DATA ]] && echo -e "===サイトを新規作成します===\n"

## ～入力項目～ ./.${SITE_NAME}_DATAに、
#  "[サイト名] [domain] [メアド]"という順番の文字列で保存される
    echo "入力をやり直したい場合ctrl+cで強制終了してください。"
    echo "ドメイン名 を入力してください 例)yahoo.jp 例)www.yahoo.co.jp"
    read -p "ドメイン名> " DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1
    #############################################
    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ $regex ]] && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    #############################################
    echo -n "${SITE_NAME} ${DOMAINNAME} ${MAILADD}" > ./.${SITE_NAME}_DATA
    echo "サイト名: ${SITE_NAME} の情報を保存しました"

## ./.${SITE_NAME}_DATA から読み取り、変数にする
export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc dddd eeee; echo "SITE_NAME=${aaaa} DOMAINNAME=${bbbb} MAILADD=${cccc}")`

## ～証明書の作成～
#  cronにて定期的に証明書更新処理を行うためport440を使う。FWの設定を忘れずに
if [ ! -f ~/certbot/letsencrypt/live/${DOMAINNAME}/.key ]; then
docker run -it --rm --name certbot \
    -v ~/certbot/letsencrypt:/etc/letsencrypt \
    -v ~/certbot/lib/letsencrypt:/var/lib/letsencrypt \
    -p 80:80 \
        certbot/certbot certonly \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
        --keep \
        --standalone \
        --dry-run \
        -d "${DOMAINNAME}" \
        -m "${MAILADD}"

sudo chown `echo $USER` -R ~/certbot
fi

## ～コンフィグtemplate記述～
#  nginx conf
envsubst '$arg $uri $1 $request_filename $fastcgi_script_name  $document_root' \
    < ./server-block.conf.temp > ./conf.d/block_${SITE_NAME}.conf

exit 0

## ～cronしょり～
if [ ! -f ./crontab ]; then #./crontabが存在しない場合、作成とcrontabの認識をさせる
    ln -s ./certbot-renew.bash /usr/local/bin/renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
## ./crontabファイルを作成する
cat << EOF > ./crontab
0 0 */3 * * /usr/local/bin/renew.bash #３日ごとに
EOF
## crontabにて./crontabファイルを認識させる
    crontab -u $USER ./crontab
fi


echo "ウェルダン"