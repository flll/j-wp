前提 https://github.com/flll/j-wp-terraform
```
sudo apt install docker-ce ca-certificates cron jq git gettext-base -y
```

下のgistのURL: https://gist.github.com/flll/561bb0e91a08fd55847acb40ec9ad765

～ダウンロード～
```
    jjbash_repo_url=561bb0e91a08fd55847acb40ec9ad765 ;\
    rm -rf ./561bb0e91a08fd55847acb40ec9ad765 ./jj.bash ;\
    git clone "https://gist.github.com/${jjbash_repo_url}.git" \
&&  ln -s "${jjbash_repo_url}/jj.bash" ./jj.bash \
&&  chmod +x ${jjbash_repo_url}/jj.bash
```

～起動～
```
./jj.bash q [param]
```
※一番最初に起動する場合、[param]の部分を` 1 2 3 `で起動することをおすすめします。

ACME 利用規約に同意します
