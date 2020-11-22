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

while [[ $valve != 1 ]]
do

read -p  "Please enter your domain: " my_domain

if [[ ! -z $my_domain ]] && [[ ! -z `dig +short "$my_domain"` ]] ; then
       valve=1
fi
done
valve=0

cp ../phpldapadmin /etc/nginx/sites-available/
sudo sed -i "s/your.domanin.com/$my_hostname/g" /etc/nginx/sites-available/phpldapadmin
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/phpldapadmin /etc/nginx/sites-enabled/

echo "================================================================================================================================"
echo " "

while [[ `. eml_verf $my_email` != OK ]]
do

read -p  "Please enter your email address: " my_email

done
   echo ""
    certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d $my_hostname
    sudo systemctl stop nginx
    sudo ps aux  |  grep -i nginx  |  awk '{print $2}' | xargs sudo kill -9
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

sudo bash . cpssl $my_domanin
sudo sed -i "s|your.domain.com|$my_hostname|g" /etc/ldap/ssl.ldif
sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/ssl.ldif
sudo sed -i "s|SLAPD_SERVICES|#SLAPD_SERVICES|g"  /etc/default/slapd
sldapservices='SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"'
echo $sldapservices >> /etc/default/slapd

sudo cp ../forcetls.ldif /etc/ldap/
sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/forcetls.ldif
sudo usermod -aG ssl-cert openldap

sudo cp ../enable-ldap-log.ldif /etc/ldap/
sudo ldapmodify -Y external -H ldapi:/// -f enable-ldap-log.ldif 
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcGlobal)" olcLogLevel -LLL
sudo echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf
sudo systemctl restart rsyslog
sudo systemctl restart slapd

