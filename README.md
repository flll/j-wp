前提 https://github.com/flll/j-wp-terraform

```
cat << 'EOF' > ~/jj.bash
#!/bin/bash
[[ ! -d j-wp/ ]] && git clone https://github.com/flll/j-wp.git
cd j-wp
git fetch && git reset --hard origin/main
chmod +x -R *
./01_init-site.bash
EOF
```

ACME 利用規約に同意します