#!/bin/bash

sleep 30
mount -t efs ${file_system_id}:/ /var/www

systemctl stop httpd
systemctl disable httpd
