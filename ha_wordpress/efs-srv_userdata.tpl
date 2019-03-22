#!/bin/bash

yum update -y
yum install httpd  elinks php php-mysql php-gd amazon-efs-utils   -y
amazon-linux-extras install epel -y
yum update -y
ls -lahtr
pwd
whoami
who




systemctl enable httpd.service
systemctl start httpd.service
timedatectl set-timezone  Europe/Kiev



mount -t efs ${file_system_id}:/ /var/www


wget http://wordpress.org/latest.tar.gz -O /tmp/latest.tar.gz
tar -xzvf /tmp/latest.tar.gz  -C /tmp/
rsync -avP /tmp/wordpress/ /var/www/html/
mkdir /var/www/html/wp-content/uploads



cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

sed -i 's/database_name_here/${db_name}/'         /var/www/html/wp-config.php
sed -i 's/username_here/${db_username}/'          /var/www/html/wp-config.php
sed -i 's/password_here/${db_password}/'          /var/www/html/wp-config.php
sed -i 's/localhost/${db_address}/'               /var/www/html/wp-config.php
chown -R apache:apache /var/www/html/*

systemctl restart httpd.service


shutdown -P +15  "I'll be back...."
