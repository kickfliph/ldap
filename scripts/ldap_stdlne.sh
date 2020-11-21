#!/bin/bash

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install slapd -y
ls -laShr /etc/ldap
sudo slapcat 
sudo slapcat | grep dn
sudo dpkg-reconfigure slapd
sudo slapcat
sudo systemctl status slapd
sudo apt-get install ldap-utils -y


dcldap=`sudo slapcat | grep dc | head -n1 | awk '{print $2}'`
aldap=`sudo slapcat | grep admin | head -n1 | awk '{print $2}'`

sudo apt install curl apt-transport-https ca-certificates php-fpm php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl php-dev libmcrypt-dev php-pear php-ldap nginx-full certbot python-certbot-nginx python3-certbot-nginx -y

echo "================================================================================================================================"
echo " "
read -p 'Please enter a valid hostname: ' my_hostname

if [ -z "$my_hostname" ]
then
    echo 'Inputs cannot be blank please try again!'
    exit 0
fi
echo " "

cp ./phpldapadmin /etc/nginx/sites-available/
sudo sed -i "s/your.domanin.com/$my_hostname/g" /etc/nginx/sites-available/phpldapadmin
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/phpldapadmin /etc/nginx/sites-enabled/

echo "================================================================================================================================"
echo " "
regex="^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$"
echo "Please enter your email address: "
read my_email
 
if [[ $my_email=~$regex ]] ; then
    echo ""
    certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d $my_hostname
    sudo systemctl stop nginx
    sudo ps aux  |  grep -i nginx  |  awk '{print $2}' | xargs sudo kill -9
else
    echo "Please enter a valid Email Address"
fi
echo ""


sudo git clone https://github.com/leenooks/phpLDAPadmin.git /var/www/html/phpldapadmin
sudo cp ./config.php   /var/www/html/phpldapadmin/config/config.php 
sudo sed -i "s|$servers->setValue('server','base',array(''));|$servers->setValue('server','base',array('$dcldap'));|g"  /var/www/html/phpldapadmin/config/config.php
sudo sed -i "s|$servers->setValue('login','bind_id','');|$servers->setValue('login','bind_id','$aldap');|g"  /var/www/html/phpldapadmin/config/config.php
sudo sed -i "s|My LDAP Server|$dcldap|g"  /var/www/html/phpldapadmin/config/config.php

nginx -t
systemctl start nginx
systemctl status nginx

#Allow OpenLDAP to use LE certificates

sudo bash ./scripts/cpssl.sh
sudo sed -i "s|your.domain.com|$my_hostname|g" /etc/ldap/ssl.ldif
sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/ssl.ldif
sudo sed -i "s|SLAPD_SERVICES|#SLAPD_SERVICES|g"  /etc/default/slapd
sldapservices='SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"'
echo $sldapservices >> /etc/default/slapd

sudo cp ./forcetls.ldif /etc/ldap/
sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/forcetls.ldif
sudo usermod -aG ssl-cert openldap

sudo cp ./enable-ldap-log.ldif /etc/ldap/
sudo ldapmodify -Y external -H ldapi:/// -f enable-ldap-log.ldif 
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcGlobal)" olcLogLevel -LLL
sudo echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf
sudo systemctl restart rsyslog
sudo systemctl restart slapd

