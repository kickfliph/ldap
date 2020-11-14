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
if [ -z "$ldapname" ]
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

