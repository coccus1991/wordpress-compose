## Description
A little docker-compose boilerplate that allow to create a wordpress installation faster with little afford.

## Requirements
Is mandatory have installed already:
* docker
* docker-compose
* Have available the ports 80 and 443 on you machine (you can change it on the docker-compose).

If you are running the project on a ubuntu server and wanna simplify docker installation you can use the script scripts/install_docker_ubuntu.bash.

## Installation
* Rename .env-example to .env and edit it.
* Run `./start.sh`

## Scripts
All scripts are located within scripts/ folder.

#### Wordpress install
**Description:** With this script you can install a version of wordpress with varnish caching in one shot.

**Usage:** `./scripts/install_wordpress.bash --HOSTNAME "yoursite.com" --ALIAS "yoursite" --ADMIN_PATH "admin" --ADMIN_USER "admin" --ADMIN_PASSWORD "password" --AD
        MIN_EMAIL "youremail@email.com"`

**Note:** Will be installed with a self signed ssl certificate. To get a valid ssl certificate from lets encrypt see the get_https script
        
#### Wordpress fix permission        
**Description:** Provide to set the correct owner and permission for wordpress folder.

**Usage:** `./scripts/fix-wordpress-permissions.bash websites/yoursite/httpdocs`

**Note:** Will create www-data user on the machine if not exist

#### install https certificate       
**Description:** Provide to set the correct owner and permission for wordpress folder.

**Usage:** `./scripts/install_https_certificate.bash youremail@email.com yoursite.com`

**Note:** After the installation you should edit nginx conf of your host and restart it as follow
```nginx
#decomment
	ssl on;
	ssl_certificate /etc/letsencrypt/live/yoursite.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/yoursite.com/privkey.pem;

#comment when get the certificate
	#include /home/snippets/self-signed.conf;
```

After that run `docker-compose exec nginx bash -c 'nginx -t' && docker-compose restart nginx`
  
#### renew https certificates         
**Description:** Provide to renew all certificates installed.

**Usage:** `./scripts/renew_https_certificate.bash`

**Note:** you can set the script to crontab  

#### backup mysql         
**Description:** Provide to make a backup of a mysql database.

**Usage:** `./scripts/backup_mysql_db.bash mydb`

**Note:** you can set the script to crontab  

## Services
* php-fpm 7.4  
* nginx 1.13.12
* mysql 5.7 
* varnish
* phpmyadmin

## Configuration files and persistence of services
Configuration files and persistence folder are located into images folder (example: images/mysql/data or images/nginx/config).

## Use ssh of containers
Launch the follow command: `docker-compose exec -it {service_name} bash`.

## More services
Within php container is already installed wp-cli and git.

## Add manually a new host
You can add more hosts manually into nginx in images/nginx/config/hosts/.