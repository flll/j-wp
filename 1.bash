#!/bin/bash -e
set -o pipefail
cd `dirname $0`

# ～入力項目～ ./DOMAINNAMEに、"[domain] [メアド]"という順番の文字列で保存される
if [ ! -f ./DOMAINNAME ]; then
    echo "ドメイン名を入力してください 例)example.com"
    echo "入力をやり直したい場合ctrl+cで強制終了してください。"
    echo -e -n "ドメインが複数ある場合カンマで区切ってください 例)example.jp,www.example.jp\n > "
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
    echo -n "${DOMAINNAME} " > ./DOMAINNAME
    echo -n "${MAILADD}" >> ./DOMAINNAME
    echo "thank you"
fi

# ./DOMAINNAME から読み取り、変数にする
export `cat ./DOMAINNAME | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

# ～証明書の作成～
# cronにて定期的に証明書更新処理を行うためport440を使う。FWの設定を忘れずに
if [ ! -f ~/certbot-persistence/letsencrypt/live/${DOMAINNAME}/.key ]; then
docker run -it --rm --name certbot \
    -v "~/certbot-persistence/letsencrypt:/etc/letsencrypt" \
    -v "~/certbot-persistence/lib/letsencrypt:/var/lib/letsencrypt" \
        certbot/certbot \
        -q \
        --rsa-key-size 4096 \
        --agree-tos \
        --break-my-certs \
            certonly \
            --keep \
            --standalone \
            --http-01-port 440

sudo chown `echo $USER` -R ~/certbot-persistence
fi

exit 0
# ～cronしょり～
if [ ! -f ./crontab ]; then #./crontabが存在しない場合、作成とcrontabの認識をさせる

    ln -s ./certbot-renew.bash /certbot-renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
cat << EOF > ./crontab
0 0 */3 * * /certbot-renew.bash
EOF
# ３日ごと↑
    crontab -u $USER ./crontab

fi


exit 0

passleng=1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
export ROOTPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 80 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=${DOMAINNAME}

docker-compose up
