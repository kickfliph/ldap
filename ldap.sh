#!/bin/bash
echo ""
echo "Press 1 for a stand alone server with Letencryt SSL certificate "
echo "Press 2 for installation LDAP server behind a structured network "
echo ""
echo -n "How you will like to install your LDAP server: "
read itslt
case $itslt in

        1 )
	   echo ""
	   echo ""   
	   echo "Stand alone installation"
           sudo bash ./scripts/ldap_stdlne.sh
                ;;

        2 )
 	   echo ""
	   echo ""   
	   echo "Structured network installation"
           sudo bash ./scripts/ldap_farm.sh
                ;;
		
       *)  echo ""
	   echo "Invalid input"
            ;;
esac
echo " "

