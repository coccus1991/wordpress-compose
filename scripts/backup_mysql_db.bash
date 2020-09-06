#!/bin/bash
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

cd $SCRIPTS_DIR
cd ..
source .env

if [ -z $1 ]; then
  die "Insert the dbname";
fi

/usr/local/bin/docker-compose exec mysql bash -c "mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${2} > /home/shared/backup_db/${2}-$(date +'%a-%H' | tr '[:upper:]' '[:lower:]').sql"
