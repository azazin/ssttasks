#!/bin/bash
mount -t efs ${file_system_id}:/ /var/www

systemctl restart httpd
