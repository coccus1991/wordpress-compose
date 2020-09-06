#!/bin/bash
HOSTNAME=""
ALIAS=""
ADMIN_PATH=""
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
DB_USER=""
DB_PW=""
DB_NAME=""
VARNISH_ENABLE="no"

#get parameters from cli inline
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
  fi
  shift
done

#cd to correct context
cd $SCRIPTS_DIR
cd ..

# Security check if the current folder is the project folder
for FILE in "docker-compose.yml" ".env"; do
  if [[ ! -f $FILE ]]; then
    echo "Isn't the correct project folder!"
    exit 1
  fi
done

for FOLDER in "images" "scripts"; do
  if [[ ! -d $FOLDER ]]; then
    echo "Isn't the correct project folder!"
    exit 1
  fi
done

# Load the docker-compose variable
source .env

##Functions
function die() {
  echo $1
  rollback
  exit 1
}

function rollback() {
  NGIX_CONFIG_PATH=images/nginx/config
  rm -fr $NGIX_CONFIG_PATH/hosts/${ALIAS}.conf
  rm -fr websites/${ALIAS}
}

function create_hostname() {
  mkdir websites/${ALIAS}/{httpdocs,logs} -p

  NGIX_CONFIG_PATH=images/nginx/config

  cp $NGIX_CONFIG_PATH/hosts_template/wordpress_varnish.conf $NGIX_CONFIG_PATH/hosts/${ALIAS}.conf

  sed -i 's/{hostname}/'$HOSTNAME'/g' $NGIX_CONFIG_PATH/hosts/${ALIAS}.conf
  sed -i 's/{folder}/'$ALIAS'/g' $NGIX_CONFIG_PATH/hosts/${ALIAS}.conf
  sed -i 's/{admin_path}/'$ADMIN_PATH'/g' $NGIX_CONFIG_PATH/hosts/${ALIAS}.conf

  if ! docker-compose exec nginx bash -c "nginx -t"; then
    die "Nginx config error"
  fi

  if ! docker-compose restart nginx; then
    die "Error to restart nginx service"
  fi
}

function install_wordpress() {

  DB_NAME=$ALIAS
  DB_USER=$ALIAS
  DB_PW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)

  #create new user and new db
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e 'CREATE DATABASE IF NOT EXISTS ${DB_NAME};'"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PW';\""
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%'; FLUSH PRIVILEGES;\""

  #install wordpress with wp-cli
  docker-compose exec php bash -c "cd ${ALIAS}/httpdocs && wp core --allow-root download && wp config create --allow-root --dbhost=mysql --dbname=${DB_NAME} --dbuser=${DB_USER} --dbpass=${DB_PW} && wp core install --allow-root --url='https://${HOSTNAME}' --title=${ALIAS} --admin_user=${ADMIN_USER} --admin_password=${ADMIN_PASSWORD} --admin_email=${ADMIN_EMAIL}"

  #configuration for varnish proxy
  docker-compose exec php bash -c "cd ${ALIAS}/httpdocs;sed -i '/DB_COLLATE/ s/$/\n\$_SERVER[\"HTTPS\"] = \"on\";/' wp-config.php"
  docker-compose exec php bash -c "cd ${ALIAS}/httpdocs;sed -i '/DB_COLLATE/ s/$/\ndefine('FORCE_SSL_ADMIN', true);/' wp-config.php"
  docker-compose exec php bash -c "cd ${ALIAS}/httpdocs;sed -i '/DB_COLLATE/ s/$/\n\n#Configuration for varnish proxy/' wp-config.php"
  docker-compose exec php bash -c "cd ${ALIAS}/httpdocs;wp option --allow-root  update permalink_structure '/%postname%'"

  #install and configure varnish purge plugin
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"delete from wp_options where option_name LIKE 'varnish_%';\" -D ${DB_NAME}"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"insert into wp_options (option_name, option_value) values ('varnish_caching_enable', '1');\" -D ${DB_NAME}"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"insert into wp_options (option_name, option_value) values ('varnish_caching_ips', 'varnish');\" -D ${DB_NAME}"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"insert into wp_options (option_name, option_value) values ('varnish_caching_hosts', '${HOSTNAME}');\" -D ${DB_NAME}"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"insert into wp_options (option_name, option_value) values ('varnish_caching_homepage_ttl', '604800');\" -D ${DB_NAME}"
  docker-compose exec mysql bash -c "mysql -u root -p${MYSQL_ROOT_PASSWORD} -e \"insert into wp_options (option_name, option_value) values ('varnish_caching_ttl', '604800');\" -D ${DB_NAME}"
}

### Instructions
if [ -z $HOSTNAME ]; then
  echo "Insert hostname without schema of your website (ex: www.yoursite.com)"
  read HOSTNAME
fi

if [ -z $ALIAS ]; then
  echo "Insert alias of your installation (is used for db_name installation_folder etc.)"
  read ALIAS
fi

if [ -z $ADMIN_PATH ]; then
  echo "Insert the admin path (will replace /wp-admin for security policy). Example for having $HOSTNAME/admin3030 insert admin3030 without slash"
  read ADMIN_PATH
fi

if [ -z $ADMIN_USER ]; then
  echo "Insert admin user:"

  read ADMIN_USER
fi

if [ -z $ADMIN_PASSWORD ]; then
  echo "Insert admin password"

  read ADMIN_PASSWORD
fi

if [ -z $ADMIN_EMAIL ]; then
  echo "Insert admin email"

  read ADMIN_EMAIL
fi

create_hostname

install_wordpress

echo "Installation done!"
echo ""
echo "============================="
echo "Admin wordpress credentials"
echo "============================="
echo "Visit: https://$HOSTNAME/$ADMIN_PATH"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
echo "============================="
echo ""
echo "============================="
echo "Database credentials"
echo "============================="
echo "User: $DB_USER"
echo "Password: $DB_PW"
echo "Db name: $DB_NAME"
echo "============================="
