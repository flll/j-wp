#!/bin/sh
read -p "ドメイン名を入力してください > " DOMAINNAME
mouichido="を入力してください。もう一度やり直してください。"
[[ -z "$DOMAINNAME" ]] && echo "ドメイン名$mouichido" && exit 1

read -p "メールアドレスを入力してください > " MAILADD
[[ -z "$MAILADD" ]] && echo "メールアドレス$mouichido" && exit 1

#$DBPASSWD

regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

[[ ! $MAILADD =~ $regex ]] && echo "メールアドレスの構文が間違っています。" && echo "ドメイン名とメールアドレスが逆になっていないか、もしくはメールアドレスをお確かめください" && exit 1
echo checkin... DONE

exit 0
cat << EOF > Caddyfile
$DOMAINNAME
tls $MAILADD
:80
root /usr/src/wordpress
gzip
fastcgi / wordpress:9000 php
rewrite {
    if {path} not_match ^\/wp-admin
    to {path} {path}/ /index.php?_url={uri}
}
errors stderr
output file /log/Caddy.log {
	rotate_size 100 # rotate after 100MB
    rotate_age 14
}
EOF
