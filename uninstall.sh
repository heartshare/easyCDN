#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH

if [ $(id -u) != "0" ]; then
	printf "Error: You must be root to run this script!"
	exit 1
fi

CDN_PATH=`pwd`
if [ `echo $CDN_PATH | awk -F/ '{print $NF}'` != "easyCDN" ]; then
	clear && echo "Please enter easyCDN script path:"
	read -p "(Default path: ${CDN_PATH}/easyCDN):" CDN_PATH
	[ -z "$CDN_PATH" ] && CDN_PATH=$(pwd)/easyCDN
	cd $CDN_PATH/
fi

clear
echo "#############################################################"
echo "# easyCDN Auto Uninstall Shell Scritp"
echo "# Env: Redhat/CentOS"
echo "# Version: $(awk '/version/{print $2}' $CDN_PATH/Changelog)"
echo ""
echo "# Distributed under the GNU General Public License, version 3.0."
echo "#"
echo "#############################################################"
echo ""

echo "Are you sure uninstall easyCDN? (y/n)"
read -p "(Default: n):" UNINSTALL
if [ -z $UNINSTALL ]; then
	UNINSTALL="n"
fi
if [ "$UNINSTALL" != "y" ]; then
	clear
	echo "==========================="
	echo "You canceled the uninstall!"
	echo "==========================="
	exit
else
	echo "---------------------------"
	echo "Yes, I decided to uninstall!"
	echo "---------------------------"
	echo ""
fi

get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo "Press any key to start uninstall..."
echo "Or Ctrl+C cancel and exit ?"
char=`get_char`
echo ""

if [ "$UNINSTALL" = 'y' ]; then

	echo "---------- tengine ----------"

	cd $CDN_PATH/src/pcre-*/
	make uninstall

	if cat /proc/version | grep -Eqi '(redhat|centos)';then
		chkconfig nginx off
	fi

	/etc/init.d/nginx stop
	killall nginx
	userdel www
	groupdel www

	rm -rf /etc/init.d/nginx
	rm -rf /usr/local/nginx
	rm -rf /tmp/nginx
	rm -rf /usr/sbin/nginx*

	echo "==========================="
	echo "Uninstall completed!"
	echo "==========================="
fi
