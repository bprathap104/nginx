#! /bin/bash
##add exceutable permission
sudo mkdir -p /var/www/html/
cd /var/www/1-http-server/
rm -rf /usr/share/nginx/html/*
sudo cp -R /var/www/1-http-server/* /usr/share/nginx/html;
cd /var/www/html/
sudo systemctl restart nginx
