easyinstall
===========

Deploy openstack is an diffcult job for large useage and some researchers.
For this purpose, we write this project for deploying openstak.

Until now, this project just can install OS by PXE. Before using `install.sh`
script, you have to check these settings.

SIMPLE STEPS
============

All we used is ubuntu-12.04

1 Packages

  You have to use `apt-get install` command to install some packages.


    apt-get install -y --force-yes dhcp3-server tftp-hpa \
        tftpd-hpa xinetd openssh-server apache2 \
        system-config-kickstart


2 Network

  You may configure you network as below. 


    auto eth0
    iface inet eth0 static
           address 192.168.1.1
           netmask 255.255.255.0
           gateway 192.168.1.1
           broadcast 192.168.1.255


3 ISO/CD path

  You may change your ISO path as below.


    iso_path=/dev/sr0  # If you use CD/DVD.
    iso_path=/tmp/ubuntu-12.04-amd64.iso # If you use iso file.


4 run install.sh  


MORE SETTINGS
=============

1 PXE-Server

  Ubuntu version: 12.04

2 ISO

  You may use both ISO/CDROM as installation source. We have checked that
  ubuntu-12.04-amd64.iso works very well. If you want to use your iso file, 
  you have to change localrc as:

       iso_path=/abs_isopath/ubuntu-12.04-amd64.iso

3 KickStart file

  We already prepare one kickstart file as a template. If you want to use your
  own kickstart file. You may use `system-config-kickstart` GUI tool to generate
  your own kickstart configuration file.

  Note: You may config your password & username in localrc.
        
        # point to you kickstart configure file.
        ks_cfg=/abs_ks_file_path/ks.cfg or ks_cfg=ks.cfg

        ROOT_PASSWORD=zaq12wsx
        USER_NAME=openstak
        USER_PASSWORD=zaq12wsx

4 Install some deb packages.

  You have to use `apt-get install` command line to install some packages. Such
  as DHCP, xinetd, tftp-hpa, apache2.

  Note: must use tftp-hpa to instead of tftp package.

5 Check your Network.

  In my network configuration, (after I use apt-get install some packages), I
  write /etc/network/interfaces as below: (default)


  auto eth0
  iface inet eth0 static
       address 192.168.1.1
       netmask 255.255.255.0
       gateway 192.168.1.1
       broadcast 192.168.1.255


  After you check your network, you may have to write your network information.
  If you use 192.168.1.1 as your IP of PXE server. You may not change localrc
  file. Otherwise you may have to change your localrc as you network info.
