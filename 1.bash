#!/bin/bash -e
set -o pipefail
cd `dirname $0`

echo "半角英数字のスペースなしでお願いします。"
echo "入力の間違えがないようご留意ください。"
echo "サイト名 を決めてください 例)wordpress 例)myblog"
read -p "サイト名> " SITE_NAME
# ～入力項目～ ./.${SITE_NAME}_DATAに、"[domain] [メアド] [http port] [https port]"という順番の文字列で保存される
if [ ! -f ./.${SITE_NAME}_DATA ]; then
    echo "新規サイトを作成します。"
    echo "入力をやり直したい場合ctrl+cで強制終了してください。"
    echo -e -n "ドメイン名 を入力してください 例)yahoo.jp 例)www.yahoo.co.jp\n ドメイン名> "
    read DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1
    #############################################
    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ $regex ]] && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    #############################################
    echo "※↓任意項目です。わからない場合はそのままエンターキーを入力してください"
    read -p "※ HTTPで使用するport番号を入力してください > " HTTP_PORTS
    read -p "※ HTTPSで使用するport番号を入力してください > " HTTPS_PORTS
    echo -n "${DOMAINNAME} ${MAILADD} ${HTTPS_PORTS:-80} ${HTTPS_PORTS:-443}" > ./.${SITE_NAME}_DATA
    echo "サイト名: ${SITE_NAME} の情報を保存しました"
fi

# ./.${SITE_NAME}_DATA から読み取り、変数にする
export `cat ./.${SITE_NAME}_DATA | (read aaaa bbbb cccc dddd; echo "DOMAINNAME=${aaaa} MAILADD=${bbbb} HTTP_PORTS=${cccc} HTTPS_PORTS=${dddd}")`
export COMPOSE_PROJECT_NAME=${SITE_NAME}

# ～証明書の作成～
# cronにて定期的に証明書更新処理を行うためport440を使う。FWの設定を忘れずに
if [ ! -f ~/certbot-${SITE_NAME}/letsencrypt/live/${DOMAINNAME}/.key ]; then
docker run -it --rm --name certbot \
    -v "~/certbot-${SITE_NAME}/letsencrypt:/etc/letsencrypt" \
    -v "~/certbot-${SITE_NAME}/lib/letsencrypt:/var/lib/letsencrypt" \
        certbot/certbot \
        -q \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
            certonly \
            --keep \
            --standalone \
            --http-01-port 440
            # stagingのアレ付き

sudo chown `echo $USER` -R ~/certbot-${SITE_NAME}
fi

# ～nginx コンフィグ設定～
cat template-server-block.conf > block_${SITE_NAME}.conf

# ～cronしょり～
if [ ! -f ./.crontab ]; then #./.crontabが存在しない場合、作成とcrontabの認識をさせる
    ln -s ./certbot-renew.bash /certbot-renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
cat << EOF > ./.crontab
0 0 */3 * * /certbot-renew.bash #３日ごと
EOF
    crontab -u $USER ./.crontab
fi

exit 0

openssl dhparam -out ~/certbot-${SITE_NAME}/letsencrypt/live/${DOMAIN}/dhparam 2048

passleng=1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
export ROOTPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 80 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 50 | head -n 1`

docker-compose up
