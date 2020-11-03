#!/bin/bash -e
set -o pipefail
cd `dirname $0`

if [ ! -f ~/.env/DATA ]; then
    read -p "ドメイン名を入力してください > " DOMAINNAME
    [[ -z "${DOMAINNAME}" ]] && echo "ドメイン名を入力してください。もう一度やり直してください。" && exit 1
    echo -n "${DOMAINNAME} " > ~/.env/DATA

    read -p "メールアドレスを入力してください > " MAILADD
    [[ -z "${MAILADD}" ]] && echo "メールアドレスを入力してください。もう一度やり直してください。" && exit 1
    #https://www.regular-expressions.info/email.html
    regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"
    [[ ! ${MAILADD} =~ ${regex} ]] && echo "メールアドレスの構文が間違っています。" && echo "ドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください" && exit 1
    echo -n ${MAILADD} > ~/.env/DATA
fi

export `cat ~/.env/DATA | (read aaaa bbbb; echo "MAILADD=$aaaa DOMAINNAME=$bbbb")`

cat << EOF > ~/Caddyfile
$DOMAINNAME
tls $MAILADD
:80
root /src
gzip
fastcgi / wordpress:9000 php
rewrite {
    if {path} not_match ^\/wp-admin
    to {path} {path}/ /index.php?_url={uri}
}
errors stderr
output file /log/Caddy.log {
  rotate_size 100
  rotate_age 14
}
EOF
fi

export ROOTPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.+\-!' | fold -w 100 | head -n 1`
export DBPASSWD=`cat /dev/urandom | tr -dc '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ,.+\-!' | fold -w 100 | head -n 1`

docker-compose up
