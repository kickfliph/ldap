#!/bin/sh

SITE=`hostname`

# move to the correct let's encrypt directory
cd /etc/letsencrypt/live/$SITE

# copy the files
cp cert.pem /etc/ssl/certs/$SITE.cert.pem
cp fullchain.pem /etc/ssl/certs/$SITE.fullchain.pem
cp privkey.pem /etc/ssl/private/$SITE.privkey.pem

# adjust permissions of the private key
chown :ssl-cert /etc/ssl/private/$SITE.privkey.pem
chmod 640 /etc/ssl/private/$SITE.privkey.pem

# restart slapd to load new certificates
systemctl restart slapd
