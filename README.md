前提 https://github.com/flll/j-wp-terraform

```
cat << EOF > ~/jj.bash
#!/bin/bash
[[ ! -d j-wp/ ]] && git clone https://github.com/flll/j-wp.git
cd j-wp
current-branch-name=`git branch | grep -e '^\\* ' | sed -e 's/^\\* //g'`
git fetch && git reset --hard origin/$current-branch-name
chmod +x -R *
./01_init-site.bash
```

ACME 利用規約に同意します