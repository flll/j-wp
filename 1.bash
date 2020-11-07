#!/bin/bash -e
set -o pipefail
cd `dirname $0`

if [ ! -f ~/.envi/DATA ]; then
    [[ ! -d ~/.envi ]] && mkdir ~/.envi
    echo "ドメイン名を入力してください。例)example.com"
    echo -e -n "サブドメインを設定している場合、含めてください。例)◯◯◯◯.example.com\n >"
    read DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1

    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    MAIL_SYNTAXERR_MESSAGE="メールアドレスの構文が間違っています。\nドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください"
    [[ ! ${MAILADD} =~ ${regex} ]] && echo -e ${MAIL_SYNTAXERR_MESSAGE} && exit 1
    echo -n "${DOMAINNAME} " > ~/.envi/DATA
    echo -n "${MAILADD}" >> ~/.envi/DATA
    echo "thank you"
fi

export `cat ~/.envi/DATA | (read aaaa bbbb; echo "DOMAINNAME=$aaaa MAILADD=$bbbb")`

# if [ ! -f ~/lego-persistence/certificates/${DOMAINNAME}.key ] || [ ! -f ~/lego-persistence/certificates/${DOMAINNAME}.key ]; then

echo atart
echo run lego
docker run \
    --rm \
    -v ~/lego-persistence:/lego \
    -e LEGO_PATH="/lego" \
        goacme/lego:latest \
        --email "${MAILADD}" \
        --domains "${DOMAINNAME}" \
        --accept-tos \
        --key-type ec384 \
        --server=https://acme-staging-v02.api.letsencrypt.org/directory \
        --tls \
            run \
            --must-staple
echo end
sudo chown `echo $USER` -R ~/lego-persistence

# fi

exit 0

export ROOTPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' | fold -w 50 | head -n 1`
export COMPOSE_PROJECT_NAME=${DOMAINNAME}

docker-compose up
