#! /bin/bash
#====================================================================
# install.sh
#
# Linux + Tengine CDN server Auto Install Script
#
# All rights reserved.
# Distributed under the GNU General Public License, version 3.0.
#
#
#====================================================================

if [ $(id -u) != "0" ]; then
    clear && echo "Error: You must be root to run this script!"
    exit 1
fi

CDN_PATH=`pwd`
if [ `echo $CDN_PATH | awk -F/ '{print $NF}'` != "easyCDN" ]; then
	clear && echo "Please enter easyCDN script path:"
	read -p "(Default path: ${CDN_PATH}/easyCDN):" CDN_PATH
	[ -z "$CDN_PATH" ] && CDN_PATH=$(pwd)/easyCDN
	cd $CDN_PATH/
fi

DISTRIBUTION=`awk 'NR==1{print $1}' /etc/issue`

if echo $DISTRIBUTION | grep -Eqi '(Red Hat|CentOS|Fedora|Amazon)';then
    PACKAGE="rpm"
else
    if cat /proc/version | grep -Eqi '(redhat|centos)';then
        PACKAGE="rpm"
    else
        if [[ "$PACKAGE" != "rpm" ]];then
            echo -e "\nNot supported linux distribution!"
            exit 0
        fi
    fi
fi

[ -r "$CDN_PATH/fifo" ] && rm -rf $CDN_PATH/fifo
mkfifo $CDN_PATH/fifo
cat $CDN_PATH/fifo | tee $CDN_PATH/log.txt &
exec 1>$CDN_PATH/fifo
exec 2>&1

/bin/bash ${CDN_PATH}/${PACKAGE}.sh

sed -i '/password/d' $CDN_PATH/log.txt
rm -rf $CDN_PATH/fifo
