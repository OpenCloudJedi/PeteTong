#!/bin/bash
########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME="conname"
ORIGINALCON="Wired\ Connection\ 1"

##### VG & LV #####
EXISTINGVGNAME="Death"
EXISTINGPESIZE="8M"
EXISTINGLVNAME="Star"
EXISTINGLVSIZE="400M"
EXISTINGFSTYPE="ext4"
EXISTINGMOUNTPOINT="/Live_Demo"
EXISTINGFSLOW="650"
EXISTINGFSHIGH="750"
VGNAME="VolGroup"
PESIZE="16"
LVNAMEONE="lv1"
LVSIZEONEMIN="450"
LVSIZEONEMAX="510"
LVMMNTONE="/mountpoint1"
LVONETYPE="ext4"
LVNAMETWO="lv2"
SWAPPART1SIZE="+256M"
LVPART2SIZE="+1G"
LVPART3SIZE="+512M"
SWAPBYTELOW="500000"
SWAPBYTEHIGH="540000"

##### Users and Groups #####
ROOTPASS="redhat"
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
FINDUSER="K2SO"
FINDDIR="/root/findfiles"
FINDFILES="/tmp/logs,/var/log/armed,/etc/droid,/home/reprogrammed"
FOUNDFILE1="logs"
FOUNDFILE2="armed"
FOUNDFILE3="droid"
FOUNDFILE4="reprogrammed"

##### Timezone #####
TIMEZONE="America/Los_Angeles"
TZSERVER="server classroom\.example\.com.*iburst"

##### Yum #####
YUMREPO1="baseurl.*=.*content\.example\.com\/rhel8.0\/x86_64\/dvd\/BaseOS"
YUMREPO2="baseurl.*=.*content\.example.com\/rhel8.0\/x86_64\/dvd\/AppStream"

##### Files and Directories #####
COLLABDIR="/collabdir"
COLLABGROUP="rebels"
TARFILE="/root/tar.tar.gz"
ORIGTARDIR="lib"  #for /var/lib This Variable works in the script if directed at the relative path
RSYNCSRC="/boot"
RSYNCDEST="/rsync_destination"
FACLONE="/tmp/fstab_copy"
FACLTWO="/tmp/fstab_copy"
FACLUSERONE="jyn"
FACLUSERTWO="cassian"
GREPFILESRC="/usr/share/dict/words"
GREPFILEDEST="/root/grepfile"



##### Apache #####
DOCROOT="/test"


##### Firewall #####
VHOST_PORT="84"
SSH_PORT="2222"

function setup_servera() {
yum install perl -y;
yum remove vim -y;
echo "Setting up servera"
#Install Apache
ssh root@servera "yum install httpd -y &>/dev/null;
#Create VirtualHost for port 84 with DocumentRoot outside of /var/www/html
cat > /etc/httpd/conf.d/servera.conf << EOF
listen 84
<VirtualHost *:84>
	ServerName	localhost
	ServerAlias	servera.lab.example.com
	DocumentRoot	$DOCROOT
	CustomLog	logs/localhost.access.log combined
	ErrorLog	logs/localhost.error.log
</VirtualHost>
<Directory $DOCROOT>
	Require all granted
</Directory>
EOF
mkdir /test
cat > /test/index.html << EOF
You got it working! The force must be <b>strong</b> with you.
EOF
mkdir -p /home-directories/remoteuser;
chmod 777  /home-directories/remoteuser;
chmod 777  /home-directories/;
setsebool -P use_nfs_home_dirs 1;
cat >> /etc/exports << EOF
/home-directories/remoteuser	*(rw,sync)
EOF
systemctl enable nfs-server.service --now;
exportfs;
firewall-cmd --add-service=nfs;
firewall-cmd --add-service=nfs --permanent;
#Delete Repositories
rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
echo "creating user: ${FINDUSER}";
useradd $FINDUSER;
#Create files to be found $FINDFILES
echo "creating files belonging to $FINDUSER"
touch {$FINDFILES};
#Change Ownership of those files to the $FINDOWNER
echo "changing ownership to ${FINDUSER} ";
chown $FINDUSER:$FINDUSER {$FINDFILES};
#Create $GREPFILE
#wget github.com/OpenCloudJedi/${GREPFILE}
#Remove firewall rule for Cockpit
firewall-cmd --zone=public --permanent --remove-service=cockpit;
#Remove networking
echo "removing network connection"
#nmcli con mod "Wired Connection 1" ipv4.method manual "${SERVERACON}";
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
useradd -M -d /home-directories/remoteuser remoteuser;
echo 'fdisk -u  /dev/vdb <<EOF' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '1' >> /root/part;
echo '' >> /root/part;
echo '+256M' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '2' >> /root/part;
echo '' >> /root/part;
echo '+256M' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '3' >> /root/part;
echo '' >> /root/part;
echo '+256M' >> /root/part;
echo 'w' >> /root/part;
echo 'EOF' >> /root/part;
chmod +x /root/part;
bash /root/part;
partprobe;
#Create existing swap
mkswap /dev/vdb1 &>/dev/null;
#Create VG and set PE size
pvcreate /dev/vdb2 /dev/vdb3 &>/dev/null
vgcreate -s $EXISTINGPESIZE $EXISTINGVGNAME /dev/vdb2 /dev/vdb3 &>/dev/null;
#Create LV
lvcreate -n $EXISTINGLVNAME -L $EXISTINGLVSIZE $EXISTINGVGNAME &>/dev/null;
#Create FileSystem
mkfs -t $EXISTINGFSTYPE /dev/${EXISTINGVGNAME}/${EXISTINGLVNAME} &>/dev/null;
#Add to /etc/fstab
echo '/dev/$EXISTINGVGNAME/$EXISTINGLVNAME $EXISTINGMOUNTPOINT $EXISTINGFSTYPE defaults 0 0' >> /etc/fstab;
echo '/dev/vdb1 swap swap defaults 0 0' >> /etc/fstab;
mkdir ${EXISTINGMOUNTPOINT}
swapon -a;
mount -a;
#Change performance profile from default to anything else...
tuned-adm profile throughput-performance;
#Install autofs, but do not enable
yum install autofs -y &>/dev/null;
#Extend grub timeout
#Fix grub
sed -i s/TIMEOUT=1/TIMEOUT=20/g /etc/default/grub ;
grub2-mkconfig > /boot/grub2/grub.cfg;
	"
}

function drop_networking() {
	ssh root@servera "echo 'nmcli connection edit <<EOF' >> /root/info;
        echo 'ethernet' >> /root/info;
        echo 'goto ipv4' >> /root/info;
        echo 'set addresses 172.25.250.66/24' >> /root/info;
        echo 'set dns 172.25.250.254' >> /root/info;
        echo 'set gateway 172.25.250.254' >> /root/info;
        echo 'set method manual' >> /root/info;
        echo 'save' >> /root/info;
        echo 'yes' >> /root/info;
        echo 'quit' >> /root/info;
        chmod +x /root/info;
        bash /root/info 2>/dev/null;
        EOF
	echo "rebooting servera now"
	reboot"
}
######################################################
###Run functions#############
setup_servera
setup_serverb
drop_networking
grep -q empire /etc/hosts 
if [ $? = 1 ]; then
	sudo echo "172.25.250.10 empire.lab.example.com" >> /etc/hosts;
	sudo echo "172.25.250.11 rebels.lab.example.com" >> /etc/hosts;
fi
echo "The setup script is finished. You may login to servera annd serverb to begin your work."
