#echo "================================================================================================================================"
#echo " "
#read -p 'Please enter a valid hostname: ' my_hostname

#if [ -z "$my_hostname" ]
#then
#    echo 'Inputs cannot be blank please try again!'
#    exit 0
#fi
#echo " "

#!/bin/bash
echo "================================================================================================================================"
echo ""

while [[ $valve != 1 ]]
do
   
read -p  "Please enter your domain: " my_domain
 
if [[ ! -z $my_domain ]] && [[ ! -z `dig +short "$my_domain"` ]] ; then
       valve=1
fi
done
valve=0

   #certbot --nginx --agree-tos --redirect --staple-ocsp --email $my_email -d $my_hostname
     #sudo systemctl stop nginx
     #sudo ps aux  |  grep -i nginx  |  awk '{print $2}' | xargs sudo kill -9

	#&& [[ $diggy == TRUE ]] 
