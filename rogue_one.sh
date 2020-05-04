#!/bin/bash

touch /etc/beenrun
function setup_servera() {
#Install Apache
ssh root@servera "yum install httpd -y;
#Create VirtualHost for port 84 with DocumentRoot outside of /var/www/html
cat > /etc/httpd/conf.d/servera.conf << EOF
listen 84
<VirtualHost *:84>
	ServerName	localhost
	DocumentRoot	$DOCROOT
	CustomLog	logs/localhost.access.log combined
	ErrorLog	logs/localhost.error.log
</VirtualHost>
EOF
wget -O /test/index.html http://cloudjedi.org/starwars.html
#Delete Repositories
rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
echo "creating user: ${FINDUSER}";
useradd $FINDUSER;
#Create files to be found $FINDFILES
echo "creating files: ${FINDFILES}"
touch {$FINDFILES};
#Change Ownership of those files to the $FINDOWNER
echo "changing ownership to ${FINDUSER} for ${FINDFILES}";
chown $FINDUSER:$FINDUSER {$FINDFILES};
#Create $GREPFILE
#wget github.com/OpenCloudJedi/${GREPFILE}
#Remove firewall rule for Cockpit
firewall-cmd --zone=public --permanent --remove-service=cockpit;
#Remove networking
echo "removing network connection"
#nmcli con delete "${SERVERACON}";
"
}
##^^^ still need to figure out how to keep this network delete from hanging
##    the script and requiring a manual break operation.

#Setup functions for serverb:

function setup_serverb() {
#Lockout users
ssh root@serverb "
head -c 32 /dev/urandom | passwd --stdin root;
head -c 32 /dev/urandom | passwd --stdin student;
cat <<- FDISKCMD | fdisk /dev/vdb &>/dev/null
	n
	p
	1

	${SWAPPART1SIZE}
	t
	1
	82
	n
	p
	2

	${LVPART2SIZE}
	t
	2
	8e
	n
	p
	3

	${LVPART3SIZE}
	t
	3
	8e
	w
	FDISKCMD
partprobe;
#Create existing swap
mkswap /dev/vdb1;
#Create VG and set PE size
pvcreate /dev/vdb2 /dev/vdb3
vgcreate -s $EXISTINGPESIZE $EXISTINGVGNAME /dev/vdb2 /dev/vdb3;
#Create LV
lvcreate -n $EXISTINGLVNAME -L $EXISTINGLVSIZE $EXISTINGVGNAME;
#Create FileSystem
mkfs -t $EXISTINGFSTYPE /dev/${EXISTINGVGNAME}/${EXISTINGLVNAME};
#Add to /etc/fstab
echo '/dev/$EXISTINGVGNAME/$EXISTINGLVNAME $EXISTINGMOUNTPOINT $EXISTINGFSTYPE defaults 0 0' >> /etc/fstab;
echo '/dev/vdb1 swap swap defaults 0 0' >> /etc/fstab;
mkdir ${EXISTINGMOUNTPOINT}
#Change performance profile from default to anything else...
tuned-adm profile throughput-performance;
#Install autofs, but do not enable
yum install autofs -y;
#Extend grub timeout
#Fix grub
sed -i s/TIMEOUT=1/TIMEOUT=20/g /etc/default/grub ;
grub2-mkconfig -o /boot/grub2/grub.cfg;"
}

if [[ -f /etc/beenrun  ]]; then
  #statements
fi
