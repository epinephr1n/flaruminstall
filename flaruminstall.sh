#!/bin/bash -       
#title			:flaruminstall.sh
#description	:Flarum install script (Origin: Nartamus) 
#author			:northeaster
#fix            :m4tronin
#date			:04/18/20
#version		:1.1
#usage			:sudo bash flaruminstall.sh
#notes			:Tested with Ubuntu 18.04 / Linux Mint 20.1 Ulyssa / ?? Debian
#==================================================================================

#Change below to what you'd like
MY_DOMAIN_NAME=mysite.ru # ваш домен
MY_EMAIL=myemail@mail.ru # ваша почта
DB_NAME=namedb # имя бд
DB_USER=userdb # имя юзера дб
DB_PSWD=passdb # пароль дб

SITES_AVAILABLE='/etc/nginx/sites-available/'

clear

echo "***************************************"
echo "*          Flarum Installer           *"
echo "*  Should work on any Ubuntu Distro   *"  
echo "*            By: Nartamus             *"
echo "***************************************"

read -p "Are you sure?(y/n) " -n 1 -r
echo    
if [[ $REPLY =~ ^[Yy]$ ]]
then
	sudo apt-get update
	sudo apt-get install nginx -y
	sudo apt-get install -y software-properties-common
	sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
	sudo add-apt-repository "deb [arch=amd64,arm64,ppc64el] http://mariadb.mirror.liquidtelecom.com/repo/10.4/ubuntu $(lsb_release -cs) main"
	sudo apt install mariadb-server -y
	sudo add-apt-repository ppa:ondrej/php -y
	sudo apt-get install php7.4-fpm php7.4-common php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip -y
	sudo apt install zip unzip -y
	sudo apt install curl git
	sudo curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
	sudo apt-get update
	sudo mkdir -p /var/www/html/$MY_DOMAIN_NAME
	cd /var/www/html/$MY_DOMAIN_NAME
	composer create-project flarum/flarum . --stability=beta
	sudo chown -R www-data:www-data /var/www/html/$MY_DOMAIN_NAME 
	sudo chmod -R 755 /var/www/html/$MY_DOMAIN_NAME
	sudo echo " server
				{
					listen 80;
					listen [::]:80;
					server_name www.$MY_DOMAIN_NAME;
					return 301 http://$MY_DOMAIN_NAME\$request_uri;
				}	
				server
				{
					listen 80;
					listen [::]:80;
					root /var/www/html/$MY_DOMAIN_NAME/public;
					index index.php index.html index.htm;
					server_name $MY_DOMAIN_NAME;
					location ~ \.php$
					{
						include snippets/fastcgi-php.conf;
						fastcgi_pass unix:/run/php/php7.4-fpm.sock;
						fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
					}
					location ~ /\.
					{
						deny all;
					}
					location = /favicon.ico
					{
						log_not_found off;
						access_log off;
					}
					location = /robots.txt
					{
						log_not_found off;
						access_log off;
						allow all;
					}
					include /var/www/html/$MY_DOMAIN_NAME/.nginx.conf;
				} " > $SITES_AVAILABLE$MY_DOMAIN_NAME.conf
	ln -s /etc/nginx/sites-available/$MY_DOMAIN_NAME.conf /etc/nginx/sites-enabled/
	sudo mysql -uroot -p$DB_PSWD -e "CREATE DATABASE $DB_NAME"
	sudo mysql -uroot -p$DB_PSWD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PSWD'"
	sudo add-apt-repository ppa:certbot/certbot -y
	sudo apt update
	sudo apt install python3-certbot-nginx -y
	certbot --nginx --agree-tos --redirect --no-eff-email -m $MY_EMAIL -d $MY_DOMAIN_NAME -d www.$MY_DOMAIN_NAME
	sudo service nginx reload
	systemctl restart php7.4-fpm.service
	systemctl restart mysql
else
	clear
fi
