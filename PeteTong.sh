#!/bin/bash
#  NAME
#	PeteTong.sh - however this can be changed to meet user
#	specific needs!
#
#  DESCRIPTION
#	This script was written to act as a template to be used with
#	instructing students who want to learn and explore Linux and
#	better understand how to manage the environment. The template
#	style should help verify the script so that instructions can
#	be managed to suit the educator/student need and to be able to
#	utilize themes.
#
#	Currently the script has been configured and tested in the RHEL
#	classroom environment and should run there properly. This may be
#	adapted adapted to work in other environments in later versions.
#
#  SETUP
#	The script should be able to run without any other major
#	dependancies and anything it would require for grading the
#	setup side should pull. The current version does NOT require
#	an internet connection to setup.
#
#	As the script deals with partitioning the device, it is
#	recommended to be run on a virtual machine so as to not cause
#	issues for the host.
#
#	The script itself can be renamed to match the theme of the
#	instructions. To run the setup:
#	# ./PeteTong.sh setup
#	The grade the work:
#	# ./PeteTong grade
#
#  Export LANG so we get consistent results throughout script
export LANG=en_US.UTF-8

########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

CHECKHOSTNAME=
PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME=
ORIGINALCON="Wired Connection 1"

##### VG & LV #####
EXISTINGVGNAME="existingvg01"
EXISTINGPESIZE="8M"
EXISTINGLVNAME="existinglv01"
EXISTINGFSTYPE="ext4"
EXISTINGMOUNTPOINT="/mountpoint"
LVNAMEONE="lv1"
LVSIZEONEMIN=
LVSIZEONEMAX=
LVMMNTONE=
LVONETYPE=
LVNAMETWO=
LVSIZETWOMIN=
LVSIZETWOMAX=
LVMMNTTWO=
LVTWOTYPE=
LVRESIZE=
SETVGNAME=
SETLVNAME=
SETMNT=

##### Users and Groups #####
GROUPNAME=
ARRAYUSERS=( user1 user2 user3 user4 )
NEWPASS=
ROOTPASS=
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
SPECIALUSR=
SPCLPWD=
SUUID=
CHAGEUSER1=
CHAGEUSER2=
PASSWDEXP="Password expires"
FINDUSER=
FINDFILES=


##### Timezone #####
TIMEZONE="America/"
TZSERVER="server classroom\.example\.com.*iburst"

##### Yum #####
YUMREPO1="http://content.example.com/rhel8.0/x86_64/dvd/BaseOS"
YUMREPO2="http://content.example.com/rhel8.0/x86_64/dvd/AppStream"

##### Files and Directories #####
HOMEDIRUSER=
USERDIR=
NOSHELLUSER=
COLLABDIR=
COLLABGROUP=
TARFILE=
ORIGTARDIR=
RSYNCSRC=
RSYNCDEST=
FACLDIRONE=
FACLDIRTWO=
FACLUSERONE=
FACLUSERTWO=
GREPFILE=

##### Cron #####
CRONUSER=
CHKCRONNUMS=
CHKCRONDAYS=


##### Apache #####
DOCROOT=


###################################################################
###################################################################
################# Setup functions section #########################
###################################################################
###################################################################

#Setup functions for servera:

function setup_servera() {
#Install Apache
ssh root@servera "yum install httpd -y;
systemctl enable httpd --now;
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

#Delete Repositories
rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
useradd $FINDUSER;
#Create files to be found $FINDFILES
touch $FINDFILES;
#Change Ownership of those files to the $FINDOWNER
chown $FINDUSER:$FINDUSER $FINDFILES;
#Create $GREPFILE
wget github.com/OpenCloudJedi/${GREPFILE}
#Remove networking
nmcli con delete "Wired Connection 1";"
}



#Setup functions for serverb:

function setup_serverb() {
#Lockout users
ssh root@serverb "
head -c 32 /dev/urandom | passwd --stdin root;
head -c 32 /dev/urandom | passwd --stdin student;
#Create an existing swap partition
#Create existing LVM partitions
touch /root/part;
echo 'fdisk -u  /dev/vdb <<EOF' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '1' >> /root/part;
echo '' >> /root/part;
echo '+256M' >> /root/part;
echo 't' >> /root/part;
echo '82' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '2' >> /root/part;
echo '' >> /root/part;
echo '+256M' >> /root/part;
echo 't' >> /root/part;
echo '2' >> /root/part;
echo '8e' >> /root/part;
echo 'n' >> /root/part;
echo 'p' >> /root/part;
echo '3' >> /root/part;
echo '' >> /root/part;
echo '+1500M' >> /root/part;
echo 't' >> /root/part;
echo '3' >> /root/part;
echo '8e' >> /root/part;
echo 'w' >> /root/part;
echo 'EOF' >> /root/part;
chmod +x /root/part;
./part;
#Create existing swap
mkswap /dev/vdb1;
#Create VG and set PE size
vgcreate -s $EXISTINGPESIZE $EXISTINGVGNAME;
#Create LV
lvcreate -n $EXISTINGLVNAME -L $EXISTINGLVSIZE $EXISTINGVGNAME;
#Create FileSystem
mkfs -t $EXISTINGFSTYPE
#Add to /etc/fstab
echo '/dev/$EXISTINGVGNAME/$EXISTINGLVNAME  $EXISTINGMOUNTPOINT    $EXISTINGFSTYPE   defaults 0 0' >> /etc/fstab;
echo '/dev/vdb1  swap	swap   defaults 0 0' >> /etc/fstab;
#Change performance profile from default to anything else...
tuned-adm profile throughput-performance;
#Install autofs, but do not enable
yum install autofs;
#Extend grub timeout
#Fix grub
sed -i s/TIMEOUT=1/TIMEOUT=20/g /etc/default/grub ;
grub2-mkconfig -o /boot/grub2/grub.cfg;"
}



###################################################################
###################################################################
################# Grading functions section #######################
###################################################################
###################################################################

#Grade functions needed for servera

#function grade_network_details
#function grade_hostname
#function grade_autoconnect
#function grade_apache
#function grade_repos
#function grade_script
#function grade_users
#function grade_groups
#function grade_passwords
#function grade_shared_directory
#function grade_file_permissions
#function grade_grep
#function grade_find


#Grade functions needed for servera

#function grade_rootpw
#function grade_lvresize
#function grade_lvm1
#function grade_lvm2
#function grade_swap
#function grade_performance_profile
#function grade_vdo
#function grade_nfs


###################################################################
###################################################################
################# Calling functions section #######################
###################################################################
###################################################################

function setup_script() {
	setup_servera
	setup_serverb
}

function lab_grade() {
#Grade functions needed for servera

# grade_network_details
#grade_hostname
#grade_autoconnect
#grade_apache
#grade_repos
#grade_script
#grade_users
#grade_groups
#grade_passwords
#grade_shared_directory
#grade_file_permissions
#grade_grep
#grade_find


#Grade functions needed for servera

#grade_rootpw
#grade_lvresize
#grade_lvm1
#grade_lvm2
#grade_swap
#grade_performance_profile
#grade_vdo
#grade_nfs
}

# case statement that calls all functions

case $1 in setup | --setup )
		#  Check if the file label has been created to prevent errors when running setup
		if [ -e "$SETUPLABEL" ]
		then
			printf "Setup has already been run on this system.\n"
		else
			setup_script
		fi
		sleep 4
		reboot
	;;
	grade | --grade )
		lab_grade
	;;
	help | --help )
			printf "Proper usage is ./scriptname setup or ./scriptname grade depending on if you are setting things up or grading. \n"
	;;
	* )
		help
	;;
esac
