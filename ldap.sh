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


sudo cp ./users.ldif /etc/ldap/
dcldap=`sudo slapcat | grep dc | head -n1 | awk '{print $2}'`
aldap=`sudo slapcat | grep admin | head -n1 | awk '{print $2}'`
sudo sed -i "s|dc=your,dc=domain,dc=com|$dcldap|g" /etc/ldap/users.ldif
echo " "
echo "================================================================================================================================"
echo " "
echo "Administrator LDAP Password"
sudo ldapadd -D "$aldap" -W -H ldapi:/// -f /etc/ldap/users.ldif
sudo ldapsearch -x -b "$dcldap" ou
echo " "
echo "================================================================================================================================"
echo " "
read -p 'Please enter new user name: ' ldapname
echo " "
read -p 'Please enter your email: ' my_email

if [ -z "$ldapname" ] || [ -z "$my_email" ]
then
    echo 'Inputs cannot be blank please try again!'
    exit 0
fi
echo " "

sudo slappasswd >> /tmp/shadow.txt
shadows=`cat /tmp/shadow.txt`
sudo rm /tmp/shadow.txt
sudo cp ./new_user.ldif /etc/ldap/
sudo mv /etc/ldap/new_user.ldif /etc/ldap/$ldapname.ldif
sudo sed -i "s/new_user/$ldapname/g" /etc/ldap/$ldapname.ldif
sudo sed -i "s|dc=your,dc=domain,dc=com|$dcldap|g"  /etc/ldap/$ldapname.ldif
sudo sed -i "s/password/$shadows/g" /etc/ldap/$ldapname.ldif
sudo ldapadd -D "$aldap" -W -H ldapi:/// -f /etc/ldap/$ldapname.ldif
sudo ldapsearch -x -b "ou=People,$dcldap"

sudo cp ./enable-ldap-log.ldif /etc/ldap/
sudo ldapmodify -Y external -H ldapi:/// -f enable-ldap-log.ldif 
sudo ldapsearch -Y EXTERNAL -H ldapi:/// -b cn=config "(objectClass=olcGlobal)" olcLogLevel -LLL
sudo echo "local4.* /var/log/slapd.log" >> /etc/rsyslog.conf
sudo systemctl restart rsyslog
sudo systemctl restart slapd

sudo apt install curl apt-transport-https ca-certificates php-fpm php-mbstring php-xmlrpc php-soap php-apcu php-smbclient php-ldap php-redis php-gd php-xml php-intl php-json php-imagick php-mysql php-cli php-ldap php-zip php-curl php-dev libmcrypt-dev php-pear php-ldap nginx-full certbot python-certbot-nginx python3-certbot-nginx -y

cp ./phpldapadmin /etc/nginx/sites-available/
sudo sed -i "s/your.domanin.com/`hostname`/g" /etc/nginx/sites-available/phpldapadmin
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/phpldapadmin /etc/nginx/sites-enabled/

certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d `hostname`
sudo systemctl stop nginx
sudo ps aux  |  grep -i nginx  |  awk '{print $2}' | xargs sudo kill -9

sudo git clone https://github.com/leenooks/phpLDAPadmin.git /var/www/html/phpldapadmin
sudo cp ./config.php   /var/www/html/phpldapadmin/config/config.php 
configphp001='$servers->setValue('server','base',array('$dcldap'));'   
echo $configphp001 | sudo tee -a /var/www/html/phpldapadmin/config/config.php 
sudo sed -i "s|$servers->setValue('login','bind_id','');|$servers->setValue('login','bind_id','$aldap');|g"  /var/www/html/phpldapadmin/config/config.php 

nginx -t
systemctl start nginx
systemctl status nginx

