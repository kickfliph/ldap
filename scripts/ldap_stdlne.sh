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

sudo apt install gnutls-bin ssl-cert dnsutils curl apt-transport-https ca-certificates php-fpm php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl php-dev libmcrypt-dev php-pear php-ldap nginx-full certbot python-certbot-nginx python3-certbot-nginx -y

echo "================================================================================================================================"
echo " "

while [[ $valve != 1 ]]
do

read -p  "Please enter a valid hostname: " my_hostname

if [[ ! -z $my_hostname ]] && [[ ! -z `dig +short "$my_hostname"` ]] ; then
       valve=1
fi
done
valve=0

cp ./phpldapadmin /etc/nginx/sites-available/
sudo sed -i "s/your.domanin.com/$my_hostname/g" /etc/nginx/sites-available/phpldapadmin
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/phpldapadmin /etc/nginx/sites-enabled/

echo "================================================================================================================================"
echo " "

while [[ `. eml_verf $my_email` != OK ]]
do

read -p  "Please enter a valid email address: " my_email

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

#. cpssl $my_hostname
#sudo cp ./ssl.ldif /etc/ldap/ssl.ldif
#sudo sed -i "s|your.domain.com|$my_hostname|g" /etc/ldap/ssl.ldif
#sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/ssl.ldif
#sudo sed -i "s|SLAPD_SERVICES|#SLAPD_SERVICES|g"  /etc/default/slapd

sudo mkdir /etc/ssl/templates
sudo cp ./ca_server.conf /etc/ssl/templates/ca_server.conf
sudo cp ./ldap_server.conf /etc/ssl/templates/ldap_server.conf
sudo sed -i "s|Example_Inc|$my_hostname|g" /etc/ssl/templates/ldap_server.conf
sudo sed -i "s|ldap_example_com|$my_hostname|g" /etc/ssl/templates/ldap_server.conf

sudo certtool -p --outfile /etc/ssl/private/ca_server.key
sudo certtool -s --load-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ca_server.conf --outfile /etc/ssl/certs/ca_server.pem
sudo certtool -p --sec-param high --outfile /etc/ssl/private/ldap_server.key
sudo certtool -c --load-privkey /etc/ssl/private/ldap_server.key --load-ca-certificate /etc/ssl/certs/ca_server.pem --load-ca-privkey /etc/ssl/private/ca_server.key --template /etc/ssl/templates/ldap_server.conf --outfile /etc/ssl/certs/ldap_server.pem

sudo usermod -aG ssl-cert openldap
sudo chown :ssl-cert /etc/ssl/private/ldap_server.key
sudo chmod 640 /etc/ssl/private/ldap_server.key
sudo cp ./ssl.ldif /etc/ldap/ssl.ldif
sudo ldapmodify -H ldapi:// -Y EXTERNAL -f ssl.ldif
sldapservices='SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"'
echo $sldapservices >> /etc/default/slapd

sudoservice slapd force-reload

sudo cp /etc/ssl/certs/ca_server.pem /etc/ldap/ca_certs.pem
tls_ca='TLS_CACERT /etc/ldap/ca_certs.pem'
sudo sed -i "s|TLS_CACERT|#TLS_CACERT|g"  /etc/ldap/ldap.conf
sudo echo $tls_ca >> /etc/ldap/ldap.conf

ldapwhoami -H ldap:// -x -ZZ

sudo cp ./enable-ldap-log.ldif /etc/ldap/
sudo ldapmodify -Y external -H ldapi:/// -f enable-ldap-log.ldif 
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcGlobal)" olcLogLevel -LLL
sudo echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf
sudo systemctl restart rsyslog
sudo systemctl restart slapd

#sudo cp ./forcetls.ldif /etc/ldap/
#sudo ldapmodify -H ldapi:// -Y EXTERNAL -f /etc/ldap/forcetls.ldif
