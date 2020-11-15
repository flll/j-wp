#!/bin/bash

## ～cronしょり～
function add-cron () {
    if [ ! -f ./crontab ]; then #./crontabが存在しない場合、作成とcrontabの認識をさせる
    echo -n "add-cron..."
        ln -s init/certbot-renew.bash /usr/local/bin/renew.bash #リポジトリ内にあるcertbot-renew.bashをルートディレクトリにシンボリックする
    ## ./crontabファイルを作成する
	cat <<-EOF > ./crontab
	0 2 */3 * * /usr/local/bin/renew.bash #深夜２時且つ３日ごとに更新を行う
	EOF
    ## crontabにて./crontabファイルを認識させる
        crontab -u $USER ./crontab
    echo "DONE"
    fi
}

