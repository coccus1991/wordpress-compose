#!/bin/bash
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd $SCRIPTS_DIR
cd ..

function die() {
    echo $1
    echo "Example of usage: ./install_https_certificate {email} {domain}"
    exit 1
}

if [ -z $1 ]; then
  die "Insert the email";
fi

if [ -z $2 ]; then
  die "Insert the domain";
fi


sudo /usr/bin/docker run -it --rm \
	-v $(pwd)/images/nginx/config/certbot/etc/letsencrypt:/etc/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/var/lib/letsencrypt:/var/lib/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/var/log/letsencrypt:/var/log/letsencrypt \
	-v $(pwd)/images/nginx/config/certbot/data/letsencrypt:/data/letsencrypt \
	certbot/certbot certonly --webroot --email ${1} --agree-tos --no-eff-email --webroot-path=/data/letsencrypt -d ${2}

