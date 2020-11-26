前提 https://github.com/flll/j-wp-terraform

下のgistのURL: https://gist.github.com/flll/561bb0e91a08fd55847acb40ec9ad765
```
     jjbash_repo_url=561bb0e91a08fd55847acb40ec9ad765 \
&&   [[ ! -d ./${jjbash_repo_url} ]] \
&&   git clone "https://gist.github.com/${jjbash_repo_url}.git"
     ( cd ${jjbash_repo_url}; git fetch && git reset --hard origin/main; chmod 755 -R . ) \
&&   ln -sb "${jjbash_repo_url}/jj.bash" ./jj.bash \
&&   chmod +x ./jj.bash \
&&   ./jj.bash [param]
```
一番最初に起動する場合、[param]の部分を 1 2 3 に置き換えて起動することをおすすめします。

ACME 利用規約に同意します
