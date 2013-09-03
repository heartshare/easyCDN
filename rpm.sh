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
	read -p "(Default path: ${CDN_PATH}):" CDN_PATH
	[ -z "$CDN_PATH" ] && CDN_PATH=$(pwd)
	cd $CDN_PATH/
fi

clear
echo "#############################################################"
echo "# Linux + Tengine CDN server Auto Install Script"
echo "# Env: Redhat/CentOS"
echo "# Version: $(awk '/version/{print $2}' $CDN_PATH/Changelog)"
echo "#"
echo "# All rights reserved."
echo "# Distributed under the GNU General Public License, version 3.0."
echo "#"
echo "#############################################################"
echo ""

echo "Please enter the server IP address:"
TEMP_IP=`ifconfig |grep 'inet' | grep -Evi '(inet6|127.0.0.1)' | awk '{print $2}' | cut -d: -f2 | tail -1`
read -p "(e.g: $TEMP_IP):" IP_ADDRESS
if [ -z $IP_ADDRESS ]; then
	IP_ADDRESS="$TEMP_IP"
fi
echo "---------------------------"
echo "IP address = $IP_ADDRESS"
echo "---------------------------"
echo ""

echo "Please enter the CDN domain:"
read -p "(Default password: cache.so):" DOMAIN
if [ -z $DOMAIN ]; then
	DOMAIN="cache.so"
fi
echo "---------------------------"
echo "CDN domain = $DOMAIN"
echo "---------------------------"
echo ""

echo "Please enter the CDN original IP address(源站IP):"
read -p "(Default password: 42.120.60.108):" ORIGIN_IP
if [ -z $ORIGIN_IP ]; then
	ORIGIN_IP="42.120.60.108"
fi
echo "---------------------------"
echo "CDN original IP address = $ORIGIN_IP"
echo "---------------------------"
echo ""

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
echo "Press any key to start install..."
echo "Or Ctrl+C cancel and exit ?"
echo ""
char=`get_char`

echo "---------- Network Check ----------"

ping -c 1 www.google.com &>/dev/null && PING=1 || PING=0

if [ -d "$CDN_PATH/src" ];then
	\mv $CDN_PATH/src/* $CDN_PATH
fi

if [ "$PING" = 0 ];then
	echo "Network Failed!"
	exit
else
	echo "Network OK"
fi

echo "---------- Update System ----------"

yum -y update

if [ ! -s /etc/yum.conf.bak ]; then
	cp /etc/yum.conf /etc/yum.conf.bak
fi
sed -i 's:exclude=.*:exclude=:g' /etc/yum.conf

echo "---------- Set timezone ----------"

rm -rf /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

yum -y install ntp
[ "$PING" = 1 ] && ntpdate -d tw.pool.ntp.org

echo "---------- Disable SeLinux ----------"

if [ -s /etc/selinux/config ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
fi

echo "---------- Set Library  ----------"

if [ ! `grep -iqw /lib /etc/ld.so.conf` ]; then
	echo "/lib" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/lib /etc/ld.so.conf` ]; then
	echo "/usr/lib" >> /etc/ld.so.conf
fi

if [ -d "/usr/lib64" ] && [ ! `grep -iqw /usr/lib64 /etc/ld.so.conf` ]; then
	echo "/usr/lib64" >> /etc/ld.so.conf
fi

if [ ! `grep -iqw /usr/local/lib /etc/ld.so.conf` ]; then
	echo "/usr/local/lib" >> /etc/ld.so.conf
fi

ldconfig

echo "---------- Set Environment  ----------"

cat >>/etc/security/limits.conf<<-EOF
* soft nproc 65535
* hard nproc 65535
* soft nofile 65535
* hard nofile 65535
EOF
ulimit -v unlimited

cat >>/etc/sysctl.conf<<-EOF
fs.file-max=65535
EOF
sysctl -p

echo "---------- Dependent Packages ----------"

yum -y install make autoconf autoconf213 gcc gcc-c++ libtool
yum -y install wget tar curl curl-devel
yum -y install openssl openssl-devel vixie-cron crontabs

echo "===================== Tengine Install ===================="

echo "---------- Pcre ----------"

cd $CDN_PATH/

if [ ! -s pcre-*.tar.gz ]; then
	wget -c "ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.33.tar.gz"
fi

tar -zxf pcre-*.tar.gz
cd pcre-*/

./configure
make && make install && ldconfig

groupadd www
useradd -g www -M -s /bin/false www

echo "---------- Tengine ----------"

cd $CDN_PATH/
mkdir -p /tmp/nginx

if [ ! -s tengine-*.tar.gz ]; then
	wget -c "http://json.so/download/tengine-latest.tar.gz"
fi

if [ ! -s ngx_cache_purge-*.tar.gz ]; then
	wget -c "http://labs.frickle.com/files/ngx_cache_purge-2.1.tar.gz"
fi

tar -zxf ngx_cache_purge-*.tar.gz
tar -zxf tengine-*.tar.gz
cd tengine-*/

./configure \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/lock/nginx.lock \
--user=www \
--group=www \
--with-http_ssl_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_realip_module \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--with-mail \
--with-mail_ssl_module \
--with-pcre \
--with-debug \
--with-ipv6 \
--with-http_concat_module \
--http-client-body-temp-path=/tmp/nginx/client \
--http-proxy-temp-path=/tmp/nginx/proxy \
--http-fastcgi-temp-path=/tmp/nginx/fastcgi \
--http-uwsgi-temp-path=/tmp/nginx/uwsgi \
--http-scgi-temp-path=/tmp/nginx/scgi \
--add-module=../ngx_cache_purge-*/
make && make install

echo "---------- Tengine Config ----------"

cd $CDN_PATH/
mv /usr/local/nginx/conf/nginx.conf /usr/local/nginx/conf/nginx.conf.bak
cp conf/nginx.conf /usr/local/nginx/conf/nginx.conf
chmod 644 /usr/local/nginx/conf/nginx.conf

mkdir /usr/local/nginx/conf/vhosts
chmod 711 /usr/local/nginx/conf/vhosts
cp conf/cdn.conf /usr/local/nginx/conf/vhosts
chmod 644 /usr/local/nginx/conf/vhosts/cdn.conf

cp conf/proxy_cache.inc /usr/local/nginx/conf/proxy_cache.inc
chmod 644 /usr/local/nginx/conf/proxy_cache.inc

sed -i 's,DOMAIN,'$DOMAIN',g' /usr/local/nginx/conf/vhosts/cdn.conf

cp conf/init.d.nginx /etc/init.d/nginx
chmod 755 /etc/init.d/nginx
chkconfig nginx on

ln -s /usr/local/nginx/sbin/nginx /usr/sbin/nginx
/etc/init.d/nginx restart

if [ ! -d "src/" ];then
	mkdir -p src/
fi
\mv ./{*gz,*-*/,package.xml} ./src >/dev/null 2>&1
/sbin/iptables -I INPUT -p tcp --dport 80 -j ACCEPT
/etc/rc.d/init.d/iptables save
/etc/rc.d/init.d/iptables restart
/etc/rc.d/init.d/httpd restart

echo "===================== System Config ===================="

echo "---------- add hosts ----------"

cat >>/etc/hosts<<-EOF
$ORIGIN_IP $DOMAIN
EOF

echo "---------- add crontab ----------"

cd $CDN_PATH/
cp conf/hit_rate.sh /usr/local/nginx/hit_rate.sh
chmod 755 /usr/local/nginx/hit_rate.sh
cat >>/var/spool/cron/root<<-EOF
*/5 * * * * /bin/bash /usr/local/nginx/hit_rate.sh /usr/local/nginx/logs/cdn/access.log > /dev/null 2>&1
EOF

clear
echo ""
echo "===================== Install completed ====================="
echo ""
echo "easyCDN install completed!"
echo ""
echo "Server ip address: $IP_ADDRESS"
echo "CDN domain: $DOMAIN"
echo "CDN original IP: $ORIGIN_IP"
echo ""
echo "tengine config file at: /usr/local/nginx/conf/nginx.conf"
echo ""
echo "============================================================="
echo ""
