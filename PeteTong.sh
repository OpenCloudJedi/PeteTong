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
<<<<<<< HEAD
CONNAME="conname"
ORIGINALCON="Wired\ Connection\ 1"
=======
CONNAME=
SERVERACON="Wired\ connection\ 1"
>>>>>>> beb381aaaa5f3d5421c50e53b7fd292ea3235801

##### VG & LV #####
EXISTINGVGNAME="existingvg01"
EXISTINGPESIZE="8M"
EXISTINGLVNAME="existinglv01"
EXISTINGLVSIZE="400M"
EXISTINGFSTYPE="ext4"
EXISTINGMOUNTPOINT="/mountpoint"
LVNAMEONE="lv1"
LVSIZEONEMIN="450M"
LVSIZEONEMAX="510M"
LVMMNTONE="/mountpoint1"
LVONETYPE="xfs"
LVNAMETWO="lv2"
LVRESIZE=
SWAPPART1SIZE="+256M"
LVPART2SIZE="+1G"
LVPART3SIZE="+512M"

##### Users and Groups #####
GROUPNAME="group1"
ARRAYUSERS=( user1 user2 user3 user4 ) #  may end up changing from array
NEWPASS="password"
ROOTPASS="password"
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
SPECIALUSR="specialuser"
SPCLPWD="specialpass"
SUUID="1313"
FINDUSER="finduser"
FINDFILES="/tmp/findfile1,/var/log/findfile2,/etc/findfile3,/home/findfile4"


##### Timezone #####
TIMEZONE="America/Los_Angeles"
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
DOCROOT="/test"


###################################################################
###################################################################
################# Setup functions section #########################
###################################################################
###################################################################

#  System functions

function help() {
	cat <<- EOF
	Usage for $PROGNAME <options>

	This is the setup script and grader for $PROGNAME.
	OPTIONS:
	   -setup		run the setup script to create the user environment
	   -grade		run the grader script to check your work
	   -help		show this help information
	EOF
}
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
wget -O /test/index.html http://cloudjedi.org/starwars.html
systemctl restart httpd &>/dev/null;
#Delete Repositories
rm -f /etc/yum.repos.d/*.repo;
#Create $FINDUSER
echo "creating user: ${FINDUSER}";
useradd $FINDUSER;
#Create files to be found $FINDFILES
echo "creating files: ${FINDFILES}"
touch {$FINDFILES};
#Change Ownership of those files to the $FINDOWNER
echo "changing ownership to "${FINDUSER}" for "${FINDFILES}"";
chown $FINDUSER:$FINDUSER {$FINDFILES};
#Create $GREPFILE
#wget github.com/OpenCloudJedi/${GREPFILE}
#Remove networking
echo "removing network connection"
nmcli con delete "${SERVERACON};"
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

###################################################################
###################################################################
################# Grade functions section #########################
###################################################################
###################################################################

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
}

##servera grading functions

#function grade_networking() {}
####################httpd section#########
#function grade_httpd() {}

function grade_hostname() {
if ! hostnamectl | grep -q $CHECKHOSTNAME
    	then
		printf "The static hostname is not configured correctly "
		print_FAIL
		return 1
	fi

	printf "The static hostname has been set correctly "
	print_PASS
	return 0
}
#function grade_firewalld() {}
#function grade_php() {}
#function grade_bashscript() {}
#function grade_users() {}
#function grade_groups() {}
#function grade_repos() {}
#function grade_shared_directory() {}
#function grade_fileperms() {}
#function grade_findfiles() {}
#function grade_grep() {}
#function grade_facl() {}

##serverb grading functions

#function grade_rootpw() {}
#function grade_lvresize() {}
#function grade_vg() {}
#function grade_lv1() {}
#function grade_lv2() {}
#function grade_performance() {}
#function grade_vdo() {}
#function grade_stratis() {}
#function grade_swap() {}
#function grade_nfs() {}
#function grade_tar() {}
#function grade_rsync() {}


#26 total objectives. Perhaps grader just counts the number of successful
#functions run and divide by 26 multiply by 100 and add a % to the end?
#with messages for 0-70 70-99 and 100% successful mastery.

###################################################################
###################################################################
################# Execute functions section #######################
###################################################################
###################################################################

function setup_script() {
#	setup_servera
	setup_serverb
}

if [[ $# -eq 0 ]]
then
	help
	exit 0
	#  This should be replaced with a help function
fi




# case statement that calls all functions

case $1 in
	setup | --setup )
	#  Check if the file label has been created to prevent errors when running setup
		#if [ -e "$SETUPLABEL" ]
		#then
	#		printf "Setup has already been run on this system.\n"
	#	else
			setup_script
	#	fi
  	#sleep 4
		#reboot
	;;
	#grade | --grade )
	#	lab_grade
	#;;
	help | --help )
			printf "Proper usage is ./scriptname setup or ./scriptname grade depending on if you are setting things up or grading. \n"
	;;
	* )
		help
	;;
esac
