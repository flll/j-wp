#!/bin/bash

docker stop nginx ||:
    docker run -it --rm --name lego \
        -v ~/j.d/lego:/lego:cached \
        -v /etc/passwd:/etc/passwd:ro \
        -v /etc/group:/etc/group:ro \
        -p 443:443 \
            goacme/lego \
            --path /lego \
            --key-type ec384 \
            --accept-tos \
            --tls \
            --domains "${DOMAINNAME}" \
            --email "${MAILADD}" \
                renew \
                --must-staple \
                --days 75
docker start nginx ||: