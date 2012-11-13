#!/bin/bash
set -e
set -o xtrace
#---------------------------------------------------
# Get the path of the script.
#---------------------------------------------------

TOP_DIR=$(cd $(dirname "$0") && pwd)

#---------------------------------------------------
# Set variable for kickstart/iso path.
#---------------------------------------------------

source $TOP_DIR/localrc
ks_cfg=${ks_cfg:-$TOP_DIR/ks.cfg}
iso_path=${iso_path:-/dev/sr0}

#---------------------------------------------------
# Change password of user and root in kickstart file.
#---------------------------------------------------
USER_NAME=${USER_NAME:-openstack}
USER_PASSWORD=${USER_PASSWORD:-zaq12wsx}
ROOT_PASSWORD=${ROOT_PASSWORD:-zaq12wsx}
sed -i "s,%ROOT_PASSWORD%,$ROOT_PASSWORD,g" $ks_cfg
sed -i "s,%USER_NAME%,$USER_NAME,g" $ks_cfg
sed -i "s,%USER_PASSWORD%,$USER_PASSWORD,g" $ks_cfg


#---------------------------------------------------
# Install deb packages. Must use tftp-hpa.
#---------------------------------------------------

apt-get install -y --force-yes dhcp3-server tftp-hpa \
tftpd-hpa xinetd openssh-server apache2

#---------------------------------------------------
# Configure the DHCP service.
#---------------------------------------------------

dhcp_conf=/etc/dhcp/dhcpd.conf

cat <<"EOF"> $dhcp_conf
ddns-update-style interim;
ignore client-updates;
allow booting;
allow bootp;

subnet %SUBNET% netmask %NETMASK% {
option routers %GATEWAY%;
option subnet-mask %NETMASK%;
option domain-name-servers %GATEWAY%;
option time-offset -18000;
range dynamic-bootp %IP_BEGIN% %IP_END%;
default-lease-time 21600;
max-lease-time 43200;
next-server %GATEWAY%;
filename "/pxelinux.0";
}
EOF

SUBNET=${SUBNET:-192.168.1.0}
NETMASK=${NETMASK:-255.255.255.0}
GATEWAY=${GATEWAY:-192.168.1.1}
IP_BEGIN=${IP_BEGIN:-192.168.1.3}
IP_END=${IP_END:-192.168.1.254}

sed -i "s,%SUBNET%,$SUBNET,g" $dhcp_conf
sed -i "s,%NETMASK%,$NETMASK,g" $dhcp_conf
sed -i "s,%GATEWAY%,$GATEWAY,g" $dhcp_conf
sed -i "s,%IP_BEGIN%,$IP_BEGIN,g" $dhcp_conf
sed -i "s,%IP_END%,$IP_END,g" $dhcp_conf

#---------------------------------------------------
# Configuration for XINETD service.
#---------------------------------------------------

TFTP_PATH=${TFTP_PATH:-/opt/tftp}

cat <<"EOF" > /etc/xinetd.conf
defaults
{
	log_type       = FILE /var/log/xinetd.log
	log_on_success = HOST EXIT DURATION
	log_on_failure = HOST ATTEMPT
	instances      = 30
	cps	       = 50 10
}
includedir /etc/xinetd.d
EOF

cat <<"EOF" > /etc/xinetd.d/tftp
service tftp
{
        socket_type             = dgram
        protocol                = udp
        wait                    = yes
        user                    = root
        server                  = /usr/sbin/in.tftpd
        server_args             = -u nobody -s %TFTP_PATH%
        disable                 = no
    	per_source		= 11
	cps 			= 100 2
	flags			= IPv4
}
EOF
sed -i "s,%TFTP_PATH%,$TFTP_PATH,g" /etc/xinetd.d/tftp

cat <<"EOF" > /etc/default/tftpd-hpa
# /etc/default/tftpd-hpa
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="%TFTP_PATH%"
TFTP_ADDRESS="0.0.0.0:69"
TFTP_OPTIONS="--secure"
EOF
sed -i "s,%TFTP_PATH%,$TFTP_PATH,g" /etc/default/tftpd-hpa

mkdir -p $TFTP_PATH
mkdir -p /usr/share/empty


#---------------------------------------------------
# Copy files for network boot.
#---------------------------------------------------

# mount iso file on a temp dir.
TEMP_DIR=`mktemp`; rm -rf $TEMP_DIR; 
mkdir -p $TEMP_DIR
mount -o loop $iso_path $TEMP_DIR

# copy iso files to http's dir.
temp_str=`cat $ks_cfg | grep url`
temp_str=${temp_str##*/}
[[ -e /var/www/$temp_str ]] && rm -rf /var/www/$temp_str
mkdir -p /var/www/$temp_str
cp -rf $TEMP_DIR/* /var/www/$temp_str/
umount $TEMP_DIR; rm -rf $TEMP_DIR

# copy network boot loader from iso files.
cp -rf /var/www/$temp_str/install/netboot/* $TFTP_PATH/
cp -rf $ks_cfg /var/www/

# touch two files, otherwise will get warnings.
# Bootstrap warning .....Packages corrupted.
touch /var/www/$temp_str/dists/precise/restricted/binary-amd64/Packages
touch /var/www/$temp_str/dists/precise/restricted/binary-i386/Packages
chmod a+r -R /var/www >/dev/null 2>&1

#---------------------------------------------------
# Change menu.......
#---------------------------------------------------

txt_cfg=$TFTP_PATH/ubuntu-installer/amd64/boot-screens/txt.cfg
[[ -e $TFTP_PATH/txt.cfg ]] && cp -rf $TFTP_PATH/txt.cfg $txt_cfg

menu_str=`cat $txt_cfg | grep append | sed -n "1p"`
menu_str=${menu_str##*append}

echo "label auto install" >> $txt_cfg
echo "    menu label ^Auto install" >> $txt_cfg
echo "    kernel ubuntu-installer/amd64/linux" >> $txt_cfg
echo "    append ks=http://$GATEWAY/`basename $ks_cfg` $menu_str" >> $txt_cfg


#---------------------------------------------------
# Restart service.......
#---------------------------------------------------
service xinetd restart
service tftpd-hpa restart
ufw disable
set +o xtrace
