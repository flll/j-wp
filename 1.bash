#!/bin/bash -e
set -o pipefail
cd `dirname $0`

# ～入力項目～ ~/.envi/DATAに、[domain] [メアド]という順番の文字列で保存される
if [ ! -f ~/.envi/DATA ]; then
    [[ ! -d ~/.envi ]] && mkdir ~/.envi
    echo "ドメイン名を入力してください。例)example.com"
    echo -e -n "サブドメインを設定している場合、含めてください。例)○○○○.example.com\n > "
    read DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1

    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ $regex ]] && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    echo -n "${DOMAINNAME} " > ~/.envi/DATA
    echo -n "${MAILADD}" >> ~/.envi/DATA
    echo "thank you"
fi

# ~/.envi/DATA から読み取り、変数にする
export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

# ～証明書の作成～
# cronにて定期的に証明書更新処理を行うためport440を使う。FWの設定を忘れずに
# ~/lego-persistence にlego必要な設定を保存
if [ ! -f ~/lego-persistence/certificates/${DOMAINNAME}.key ]; then
docker run \
    --rm \
    -v ~/lego-persistence:/lego \
    -p "440:440" \
    -e LEGO_PATH="/lego" \
        goacme/lego:latest \
        --email "${MAILADD}" \
        --domains "${DOMAINNAME}" \
        --server=https://acme-staging-v02.api.letsencrypt.org/directory \
        --accept-tos \
        --key-type ec384 \
        --tls \
        --tls.port 127.0.0.1:440 \
            run \
            --must-staple

sudo chown `echo $USER` -R ~/lego-persistence
fi
#TODO cronで定期的にlego renewを行う
# cronたｂ → /renew
#権限を付与することを忘れずに
#環境別の対策としてrenewはシンボリックを導入

ln -s ./renew.sh /renew.sh
crontab -u $USER ./crontab

exit 0

passleng=1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
export ROOTPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 80 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '$passleng' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=${DOMAINNAME}

docker-compose up
