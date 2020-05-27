#!/bin/sh
apt update
apt upgrade

apt install locales apache2 libapache2-mod-php php-pear php php-cgi php-cli php-common php-fpm php-gd php-json php-mysql php-readline php curl php-intl php-ldap mcrypt php-xml php-mbstring zip unzip php-zip
service apache2 restart

mkdir /var/www/html/syspass

git clone https://github.com/nuxsmin/sysPass.git  /var/www/html/syspass
chown www-data -R /var/www/html/syspass
chmod 750 /var/www/html/syspass/app/config /var/www/html/syspass/app/backup

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'e0012edf3e80b6978849f5eff0d4b4e4c79ff1609dd1e613307e16318854d24ae64f26d17af3ef0bf7cfb710ca74755a') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

./install_composer.sh

php composer.phar install --no-dev

a2enmod ssl
a2ensite default-ssl.conf
a2dissite 000-default.conf
service apache2 restart