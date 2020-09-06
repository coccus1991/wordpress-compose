#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd $SCRIPTS_DIR
cd ..

if [ ! -d "$1" ]; then
  echo "The path is not exist"
  exit 1
fi

id -u www-data &>/dev/null || useradd www-data

chown -R www-data:www-data $1

WP_OWNER=$(stat -c '%U' $1) # <-- wordpress owner
WP_GROUP=$(stat -c '%G' $1) # <-- wordpress group
WP_ROOT=$1                  # <-- wordpress root directory

# reset to safe defaults
chown -R ${WP_OWNER}:${WP_GROUP} ${WP_ROOT}
find ${WP_ROOT} -type d -exec chmod 755 {} \;
find ${WP_ROOT} -type f ! -path '*wp-content*' -exec chmod 644 {} \;

chmod 660 ${WP_ROOT}/wp-config.php

# allow wordpress to manage wp-content
chmod -R 664 ${WP_ROOT}/wp-content

find ${WP_ROOT}/wp-content -type d -exec chmod 775 {} \;

echo "Fixed!"