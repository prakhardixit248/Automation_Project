#!/bin/bash

set -u
set -e

# variables
myname='prakhar'
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket=upgrad-prakhar


# funnctions
update_package(){
apt update -y 2>&1
apt upgrade -y 2>&1
apt autoremove -y 2>&1
apt autoclean -y 2>&1
}
install_package(){		
if dpkg -s $1 > /dev/null 2>&1; then
	echo "Package already installed"
else
   	apt install $1 -y
fi
}

check_running(){

if systemctl status $1 | grep -w "Active: active (running)" > /dev/null 2>&1; then
	echo "$1 is running on system !!"
else
	echo "$1 is not running"
	systemctl start apache2
	exit 1;
fi
}
check_enabled(){
if systemctl list-unit-files apache2.service | grep enabled > /dev/null 2>&1; then
	echo "$1 is enabled !!"
else
    echo "Enabling $1 service"
    systemctl enable $1
fi  
}

archive_logs(){
cd /var/log/apache2/
tar -czf /tmp/${myname}-httpd-logs-${timestamp}.tar *.log
}

copy_tar()
{
aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar
}

main (){
update_package
install_package apache2
check_running apache2
check_enabled apache2
archive_logs
install_package awscli
copy_tar
}	

main | tee logs.txt
	



