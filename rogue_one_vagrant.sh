#!/bin/bash
########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

CHECKHOSTNAME="server1.eight.example.com"
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
ARRAYUSERS=( user1 user2 user3 user4 ) #  may end up changing from array
NEWPASS="password"
ROOTPASS="redhat"
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
SPECIALUSR="specialuser"
SPCLPWD="specialpass"
SUUID="1313"
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
HOMEDIRUSER=
USERDIR=
NOSHELLUSER=
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

##### Cron #####
CRONUSER=
CHKCRONNUMS=
CHKCRONDAYS=


##### Apache #####
DOCROOT="/test"


##### Firewall #####
VHOST_PORT="82"
SSH_PORT="2222"

function setup_servera() {
#Install Apache
ssh vagrant@server1.eight.example.com "cat > /home/vagrant/building.repo << EOF
[BaseOS]
name=BaseOS
baseurl=http://repo.eight.example.com/BaseOS
enabled=1
gpgcheck=0
[AppStream]
name=AppStream
baseurl=http://repo.eight.example.com/AppStream
enabled=1
gpgcheck=0
EOF
sudo cp /home/vagrant/building.repo /etc/yum.repos.d/building.repo
sudo yum install httpd -y &>/dev/null;
#Create VirtualHost for port 84 with DocumentRoot outside of /var/www/html
cat > /home/vagrant/servera.conf << EOF
listen 84
<VirtualHost *:84>
	ServerName	localhost
	DocumentRoot	$DOCROOT
	CustomLog	logs/localhost.access.log combined
	ErrorLog	logs/localhost.error.log
</VirtualHost>
EOF
sudo sed -i s/=permissive/=enforcing/g /etc/selinux/config;
sudo setenforce 1;
sudo cp /home/vagrant/servera.conf /etc/httpd/conf.d/server1.conf
sudo mkdir /test
sudo wget -O /test/index.html http://cloudjedi.org/starwars.html &>/dev/null
#Delete Repositories
sudo rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
echo "creating user: ${FINDUSER}";
sudo useradd $FINDUSER;
#Create files to be found $FINDFILES
echo "creating files for $FINDUSER"
sudo touch {$FINDFILES};
#Change Ownership of those files to the $FINDOWNER
echo "changing ownership to ${FINDUSER} ";
sudo chown $FINDUSER:$FINDUSER {$FINDFILES};
#Create $GREPFILE
#wget github.com/OpenCloudJedi/${GREPFILE}
#Remove firewall rule for Cockpit
sudo firewall-cmd --zone=public --permanent --remove-service=cockpit;
#Remove networking
#echo "removing network connection"
#nmcli con delete "${SERVERACON}";
"
}
##^^^ still need to figure out how to keep this network delete from hanging
##    the script and requiring a manual break operation.

#Setup functions for serverb:

function setup_serverb() {
#Lockout users
ssh vagrant@server2.eight.example.com "
sudo head -c 32 /dev/urandom | passwd --stdin root;
sudo head -c 32 /dev/urandom | passwd --stdin vagrant;
echo 'fdisk -u  /dev/sdb <<EOF' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '1' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '2' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'n' >> /home/vagrant/part;
echo 'p' >> /home/vagrant/part;
echo '3' >> /home/vagrant/part;
echo '' >> /home/vagrant/part;
echo '+256M' >> /home/vagrant/part;
echo 'w' >> /home/vagrant/part;
echo 'EOF' >> /home/vagrant/part;
sudo chmod +x /home/vagrant/part;
sudo bash /home/vagrant/part;
sudo partprobe;
#Create existing swap
sudo mkswap /dev/sdb1 &>/dev/null;
#Create VG and set PE size
sudo pvcreate /dev/sdb2 /dev/sdb3 &>/dev/null
sudo vgcreate -s $EXISTINGPESIZE $EXISTINGVGNAME /dev/sdb2 /dev/sdb3 &>/dev/null;
#Create LV
sudo lvcreate -n $EXISTINGLVNAME -L $EXISTINGLVSIZE $EXISTINGVGNAME &>/dev/null;
#Create FileSystem
sudo mkfs -t $EXISTINGFSTYPE /dev/${EXISTINGVGNAME}/${EXISTINGLVNAME} &>/dev/null;
#Add to /etc/fstab
echo '/dev/$EXISTINGVGNAME/$EXISTINGLVNAME $EXISTINGMOUNTPOINT $EXISTINGFSTYPE defaults 0 0' | sudo tee -a /etc/fstab;
echo '/dev/sdb1 swap swap defaults 0 0' | sudo tee -a /etc/fstab;
sudo mkdir ${EXISTINGMOUNTPOINT}
sudo swapon -a;
sudo mount -a;
#Change performance profile from default to anything else...
sudo tuned-adm profile throughput-performance;
#Install autofs, but do not enable
sudo yum remove vim -y &>/dev/null;
#Extend grub timeout
#Fix grub
sudo sed -i s/TIMEOUT=1/TIMEOUT=20/g /etc/default/grub ;
sudo grub2-mkconfig -o /boot/grub2/grub.cfg;"
}

######################################################
###Run functions#############
setup_servera
setup_serverb
grep -q empire /etc/hosts
if [ $? = 1 ]; then
	echo "172.25.250.10 empire.lab.example.com" | tee -a /etc/hosts;
	echo "172.25.250.11 rebels.lab.example.com" | tee -a /etc/hosts;
fi
echo "The setup script is finished. You may login to servera annd serverb to begin your work."
