#!/bin/bash

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd $SCRIPTS_DIR
cd ..

sudo /usr/bin/docker run -it --rm \
	-v $(pwd)/images/nginx/config/certbot/etc/letsencrypt:/etc/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/var/lib/letsencrypt:/var/lib/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/var/log/letsencrypt:/var/log/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/data/letsencrypt:/data/letsencrypt \
	certbot/certbot certificates

