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

CHECKHOSTNAME="servera.lab.example.com"
PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME="conname"
ORIGINALCON="Wired\ Connection\ 1"

##### VG & LV #####
EXISTINGVGNAME="existingvg01"
EXISTINGPESIZE="8M"
EXISTINGLVNAME="existinglv01"
EXISTINGLVSIZE="400M"
EXISTINGFSTYPE="ext4"
EXISTINGMOUNTPOINT="/mountpoint"
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
FINDUSER="finduser"
FINDDIR="/root/findfiles"
FINDFILES="/tmp/findfile1,/var/log/findfile2,/etc/findfile3,/home/findfile4"
FOUNDFILE1="findfile1"
FOUNDFILE2="findfile2"
FOUNDFILE3="findfile3"
FOUNDFILE4="findfile4"

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
function grade_httpd() {
	printf "Checking Apache service and SELINUX. "
	if ! getenforce | grep -q 'Enforcing'; then
    print_FAIL
    echo -e '\033[1;31m - selinux is not set to enforcing\033[0;39m'
    return 1
  fi
	if ! systemctl status httpd.service &> /dev/null; then
    print_FAIL
    echo -e '\033[1;31m - httpd.service is not running.\033[0;39m'
    return 1
  fi
  if ! systemctl status httpd 2> /dev/null | grep -q '^[[:space:]]*Loaded.*enabled'; then
    print_FAIL
    echo -e '\033[1;31m - httpd.service not set to be started at boot.\033[0;39m'
    return 1
  fi
  if ! curl -v --silent localhost:84 2>&1 | grep -q 'You got it working'; then
    print_FAIL
    echo -e '\033[1;31m - You are not serving the correct webpage.\033[0;39m'
    return 1
  fi
	printf "The webite is serving the page correctly.  "
	print_PASS
	return 0
}

	function grade_hostname() {
		if ! hostnamectl | grep -q "${CHECKHOSTNAME}"
    	then
		echo -e '\033[1;31m - The static hostname is not configured correctly \033[0;39m'
		print_FAIL
		return 1
	fi

	printf "The static hostname has been set correctly "
	print_PASS
	return 0
}

	function grade_firewalld() {
	printf "Checking firewall configuration on servera. "
  firewall-cmd --zone=public --list-ports | grep ${VHOST_PORT}/tcp &>/dev/null
  	RESULT=$?
  if   [ "${RESULT}" -ne 0 ] 
  then
    print_FAIL
	  echo -e "\033[1;31m - Either no firewall rule for port ${VHOST_PORT} is present, or it is misconfigured. \033[0;39m"
    return 1
  fi 
	  firewall-cmd --zone=public --list-services | grep cockpit &>/dev/null
	RESULT=$?
	if   [ "${RESULT}" -ne 0 ]
then
    print_FAIL
    return 1
    	echo -e "\033[1;31m - Firewall rule for cockpit is not enabled. \033[0;39m"
  fi
	print_PASS
	return 0	
}

	function grade_php() {
		printf "Checking to see that PHP is installed and the correct version."
		rpm -qi php | grep "package php is not installed" &>/dev/null
		RESULT=$?
          if [ "${RESULT}" -ne 1 ]; then
		  print_FAIL
		  echo -e "\033[1;31m - PHP does not appear to be installed. \033[0;39m"
		return 1
	  fi
	  rpm -qi php | grep "Version     : 7.2.11" &>/dev/null
	  RESULT=$?
          if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - PHP does not appear to be the correct version. \033[0;39m"
                return 1
          fi
	  	print_PASS
	  	return 0
  }

#function grade_bashscript() {}
	function grade_users() {
		printf "Checking for correct user setup. "

	  grep "${GROUPNAME}:x:*" /etc/group &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo -e "\033[1;31m - The $GROUPNAME group does not exist.\033[0;39m"
	    return 1
	  fi

	  for USER in $SPECIALUSR $ARRAYUSERS; do
	    grep "$USER:x:.*" /etc/passwd &>/dev/null
	    RESULT=$?
	    if [ "${RESULT}" -ne 0 ]; then
	      print_FAIL
	      echo -e "\033[1;31m - The user $USER has not been created.\033[0;39m"
	      return 1
	    fi
	  done

	  for USER in ${ARRAYUSERS}; do
	    grep "${GROUPNAME}:x:.*$USER.*" /etc/group &>/dev/null
	    RESULT=$?
	    if [ "${RESULT}" -ne 0 ]; then
	      print_FAIL
	      echo -e "\033[1;31m - The user $USER is not in the $GROUPNAME group.\033[0;39m"
	      return 1
	    fi
	  done

#Still need an evaluation for primary group.

	  #if ! primary_group 'BB8:' 'BB8' ||
	  #! primary_group 'R2D2:' 'R2D2' ||
	  #! primary_group 'C3PO:' 'C3PO' ||
	  #! primary_group 'badguys:' 'Vader'; then
		#return 1
	  #fi

	  if ! cat /etc/passwd | grep "$SPECIALUSR" | grep -q "$SUUID"; then
	    print_FAIL
	    echo -e "\033[1;31m - The user ${SPECIALUSR}s uid is not set to $SUUID \033[0;39m"
	    return 1
	  fi

	  for USER in ${ARRAYUSERS}; do
	    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
	    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
	    PERLCOMMAND="print crypt(\"${NEWPASS}\", \"\\\$6\\\$${SALT}\");"
	    NEWHASH=$(perl -e "${PERLCOMMAND}")

	    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
	      print_FAIL
	      echo -e "\033[1;31m - The password for user $USER is not set to ${NEWPASS}\033[0;39m"
	      return 1
	    fi
	  done

	  for USER in $SPECIALUSR; do
	    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
	    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
	    PERLCOMMAND="print crypt(\"${SPCLPWD}\", \"\\\$6\\\$${SALT}\");"
	    NEWHASH=$(perl -e "${PERLCOMMAND}")

	    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
	      print_FAIL
	      echo -e "\033[1;31m - The password for user $USER is not set to ${SPCLPWD} \033[0;39m"
	      return 1
	    fi
	  done
	  	print_PASS
		return 0
	}


function grade_repos() {
	grep -R "$YUMREPO1" /etc/yum.repos.d/ &>/dev/null
	local result=$?

	if [[ "${result}" -ne 0 ]]; then
		print_FAIL
		echo -e '\033[1;31m - Check your BaseOS yum repository again \033[0;39m'
		return 1
	fi
	grep -R $YUMREPO2 /etc/yum.repos.d/ &>/dev/null
	local result=$?

	if [[ "${result}" -ne 0 ]]; then
		print_FAIL
		echo -e '\033[1;31m - Check your AppStream yum repository again \033[0;39m'
		return 1
	fi
	printf "Your repositories have been setup correctly. Both appear to work. "
        print_PASS
        return 0
}

function grade_shared_directory() {
	if [ $(stat -c %G "$COLLABDIR") != "$COLLABGROUP" ]
	then
		print_FAIL
		echo  -e "\033[1;31m - %s does not have correct group ownership (${COLLABGROUP}) on $COLLABDIR \033[0;39m"
		return 1
	fi

	if [ $(stat -c %a "$COLLABDIR") -ne 2770 ]
	then
		print_FAIL
		echo -e "\033[1;31m %s does not have correct permissions \033[0;39m"
		return 1
	fi
	printf "Your shared directory has been setup correctly with the correct ownershop and permissions."
        print_PASS
        return 0
}

	function grade_fileperms() {
		printf "Checking permissions and ownership.
"

	  if ! [ -d ${COLLABDIR} ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Directory ${COLLABDIR} not found. \033[0;39m"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^# owner: root$' 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - Ownership of ${COLLABDIR} not set to 'root'. \033[0;39m"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q "^# group: ${COLLABGROUP}$" 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - Group ownership of ${COLLABDIR} not set to ${COLLABGROUP}\033[0;39m"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^user::rwx$' 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - User permissions not set to 'rwx' on ${COLLABDIR}. \033[0;39m"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^group::rwx$' 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - Group permissions not set to 'rwx' on ${COLLABDIR}. \033[0;39m"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^other::---$' 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - Other permissions not set to no access on ${COLLABDIR}. \033[0;39m"
	    return 1
	  fi
		if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q 'flags: -s-' 2> /dev/null; then
	    print_FAIL
	    echo -e "\033[1;31m - Special permissions (SETGID bit) not set on ${COLLABDIR}. \033[0;39m"
	    return 1
	  fi

	  printf "Your collabrative directory appears to be setup correctly. "
	  print_PASS
	  return 0
	}

	function grade_findfiles() {
		  printf "Checking ${FINDDIR} has the correct files.
"

		  if [ ! -d ${FINDDIR} ]; then
		    print_FAIL
		    echo -e "\033[1;31m - The target directory ${FINDDIR} does not exist. \033[0;39m"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FINDUSER}"; then
		    print_FAIL
		    echo -e "\033[1;31m - ${FINDUSER}s files were not copied properly. \033[0;39m"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE1}"; then
		    print_FAIL
		    echo -e "\033[1;31m - ${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE1}. \033[0;39m"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE2}"; then
		    print_FAIL
		    echo -e "\033[1;31m - ${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE2}. \033[0;39m"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE3}"; then
		    print_FAIL
		    echo -e "\033[1;31m - ${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE3}. \033[0;39m"
		    return 1
		  fi

			if ! ls ${FINDDIR} | grep -q "${FOUNDFILE4}"; then
		    print_FAIL
		    echo -e "\033[1;31m - ${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE4}. \033[0;39m"
		    return 1
		  fi

		  printf "The files appear to have been copied successfully"
		  print_PASS
		  return 0

	}
#function grade_grep() {}

	function grade_facl() {
		if [ ! -d $FACLDIRONE ]
  then
    print_FAIL
    echo -e "\033[1;31m - %s does not exist \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p "$FACLONE" | grep -q "^user:"$FACLUSERONE":")
  local checkfacl="user:"$FACLUSERONE":rw"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - User $FACLUSERONE permission settings on %s are incorrect. \033[0;39m"
     return 1
  fi
  fi

	if [ ! -d "FACLDIRTWO" ]
  then
    print_FAIL
    echo -e "\033[1;31m - %s does not exist. \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p "$FACLTWO" | "^user:"$FACLUSERTWO":")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - User $FACLUSERTWO permission settings on %s are incorrect. \033[0;39m"
     return 1
		 if [ ! -d "FACLDIRTWO" ]
  then
    print_FAIL
    echo -e "\033[1;31m - %s does not exist. \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p "$FACLDIRTWO" | "^user:"$FACLUSERTWO":")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - User permission settings on %s are incorrect. \033[0;39m"
     return 1
  fi
  fi
  fi
  fi
  	printf "The facls appear to have been configured correctly."
  	print_PASS
	return 0
	}

##serverb grading functions

	function grade_rootpw() {
		for USER in root; do
	    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
	    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
	    PERLCOMMAND="print crypt(\"${ROOTPASS}\", \"\\\$6\\\$${SALT}\");"
	    NEWHASH=$(perl -e "${PERLCOMMAND}")

	    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
	      print_FAIL
	      echo -e "\033[1;31m - The password for user $USER is not set to ${ROOTPASS}. \033[0;39m"
	      return 1
	    fi
	  done
	  printf "The root password appears to be configured correctly."
	  print_PASS
	  return 0
	}
	function grade_lvresize() {
		printf "Checking completion of Logical Volume resize. "
		read LV VG A SIZE A <<< $(lvs --noheadings --units=m ${EXISTINGVGNAME} 2>/dev/null | grep ${EXISTINGLVNAME}) &> /dev/null
	  if [ "${LV}" != "${EXISTINGLVNAME}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - No LV named ${EXISTINGLVNAME} found in VG ${EXISTINGVGNAME} we may have destroyed the existing data. \033[0;39m"
	    return 1
	  fi
	  SIZE=$(echo ${SIZE} | cut -d. -f1)
	  if  ! (( ${EXISTINGFSLOW} < ${SIZE} && ${SIZE} < ${EXISTINGFSHIGH} )); then
	    print_FAIL
	    echo -e "\033[1;31m - Logical Volume ${EXISTINGLVNAME} is not the correct size.\033[0;39m"
	    return 1
	  fi
	}
	function grade_vg() {
		printf "Checking for new VG with correct PE size"

	  read VG A A A A SIZE A <<< $(vgs --noheadings --units=m ${VGNAME} 2>/dev/null) &> /dev/null
	  if [ "${VG}" != "$VGNAME" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - No Volume Group named ${VGNAME} found. \033[0;39m"
	    return 1
	  fi

	  if ! vgdisplay ${VGNAME} | grep 'PE Size' | grep -q "${PESIZE}"; then
	    print_FAIL
	    echo -e "\033[1;31m - Incorrect PE size on volume group $VGNAME. \033[0;39m"
	    return 1
	  fi
	  	print_PASS
               	return 0
	}

	function grade_lv1() {
		printf "Checking the Logical Volume Setup."
		read LV VG A SIZE A <<< $(lvs --noheadings --units=m ${VGNAME} 2>/dev/null | grep ${LVNAMEONE}) &> /dev/null
	  if [ "${LV}" != "${LVNAMEONE}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - No LV named ${LVNAMEONE} found in VG ${VGNAME} \033[0;39m"
	    return 1
	  fi
	  SIZE=$(echo ${SIZE} | cut -d. -f1)
	  if  ! (( ${LVSIZEONEMIN} < ${SIZE} && ${SIZE} < ${LVSIZEONEMAX} )); then
	    print_FAIL
	    echo -e "\033[1;31m - Logical Volume ${LVNAMEONE} is not the correct size.\033[0;39m"
	    return 1
	  fi
		read DEV TYPE MOUNTPOINT <<< $(df --output=source,fstype,target ${LVMMNTONE} 2> /dev/null | grep ${LVMMNTONE} 2> /dev/null) &> /dev/null
	  if [ "${DEV}" != "/dev/mapper/${VGNAME}-${LVNAMEONE}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Wrong device mounted on ${LVMMNTONE}. \033[0;39m"
	    return 1
	  fi
	  if [ "${TYPE}" != "${LVONETYPE}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Wrong file system type mounted on ${LVMMNTONE}. \033[0;39m"
	    return 1
	  fi
	  if [ "${MOUNTPOINT}" != "${LVMMNTONE}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Wrong mountpoint. \033[0;39m"
	    return 1
	  fi
	  	print_PASS
               	return 0
	}

	function grade_performance() {
		printf "Checking performance profile. "
		TUNED=$(tuned-adm active)
		if [ "${TUNED}" = "Current active profile: virtual-guest" ]; then
			print_PASS
			return 0
		else
			print_FAIL
			echo -e "\033[1;31m - The tuning profile should be set to virtual-guest.\033[0;39m"
			return 1
		fi
	}

	function grade_vdo() {
		printf "Checking that VDO is properly configured. "
		rpm -qi vdo | grep "package vdo is not installed" &>/dev/null
                RESULT=$?
        if [ "${RESULT}" -ne 1 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - VDO does not appear to be installed. \033[0;39m"
                return 1
	fi

	systemctl is-enabled vdo.service | grep -q "enabled"
		RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - VDO is not enabled at boot time. \033[0;39m"
                return 1
        fi
	vdo list | grep -q vdokilledtheradiostar
		RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - VDO volume vdokilledtheradiostar unavailable. \033[0;39m"
                return 1
        fi
	vdo status --name=vdokilledtheradiostar | grep -q "Logical size: 50G"
		RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - VDO volume vdokilledtheradiostar doesn't have a logical size of 50G. \033[0;39m"
                return 1
        fi
		print_PASS
		return 0
}

	function grade_stratis() {
		printf "Checking that Stratis volume exists and is set to be available at boot time. "
		rpm -qi stratisd | grep "package stratisd is not installed" &>/dev/null
                RESULT=$?
        if [ "${RESULT}" -ne 1 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - stratisd does not appear to be installed. \033[0;39m"
                return 1
        fi
		rpm -qi stratis-cli | grep "package stratis-cli is not installed" &>/dev/null
                RESULT=$?
        if [ "${RESULT}" -ne 1 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - stratis-cli does not appear to be installed. \033[0;39m"
                return 1
        fi
	systemctl is-enabled stratisd | grep -q "enabled"
                RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - stratisd service is not enabled at boot time. \033[0;39m"
                return 1
        fi

	grep -q x-systemd.requires=stratisd.service /etc/fstab
		RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - Stratis volume missing x-systemd.requires=stratisd.service option in /etc/fstab. \033[0;39m"
                return 1
        fi
	stratis pool list | grep -q StratisGenerator
	RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - Stratis pool StratisGenerator does not exist. \033[0;39m"
                return 1
        fi
	stratis filesystem | grep -q Codes
	RESULT=$?
        if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - Stratis filesystem called Codes was not found. \033[0;39m"
                return 1
        fi
		print_PASS

	}

	function grade_swap() {
		printf "Checking for new swap partition. "

	  NUMSWAPS=$(( $(swapon -s | wc -l) - 1 ))
	  if [ ${NUMSWAPS} -lt 1 ]; then
	    print_FAIL
	    echo -e "\033[1;31m - No swap partition found. Did you delete the existing? \033[0;39m"
	    return 1
	  fi
	  if [ ${NUMSWAPS} -gt 2 ]; then
	    print_FAIL
	    echo -e "\033[1;31m - More than 2 swap partitions  found. \033[0;39m"
	    return 1
	  fi

	  read PART TYPE SIZE USED PRIO <<< $(swapon -s 2>/dev/null | tail -n1 2>/dev/null) 2>/dev/null
	  if [ "${TYPE}" != "partition" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Swap is not a partition. \033[0;39m"
	  fi
	  if  ! (( ${SWAPBYTELOW} < ${SIZE} && ${SIZE} < ${SWAPBYTEHIGH} )); then
	    print_FAIL
	    echo -e "\033[1;31m - Swap is not the correct size. \033[0;39m"
	    return 1
	  fi

	  if ! grep -q 'UUID.*swap' /etc/fstab; then
	    print_FAIL
	    echo -e "\033[1;31m - Swap isn't mounted from /etc/fstab by UUID. \033[0;39m"
	    return 1
	  fi

	  print_PASS
	  return 0
	}
	function grade_nfs() {
		printf "Checking automounted home directories. "
	  TESTUSER=production5
	  TESTHOME=/localhome/${TESTUSER}
	  DATA="$(su - ${TESTUSER} -c pwd 2>/dev/null)"
	  if [ "${DATA}" != "${TESTHOME}" ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Home directory not available for ${TESTUSER}. \033[0;39m"
	    return 1
	  fi
	  if ! mount | grep 'home-directories' | grep -q nfs; then
	    print_FAIL
	    echo -e "\033[1;31m - ${TESTHOME} not mounted over NFS. \033[0;39m"
	    return 1
	  fi
	  	  print_PASS
	  return 0
	}

	function grade_tar() {
		printf "Checking for correct compressed archive. "

	  if [ ! -f $TARFILE ]; then
	    print_FAIL
	    echo -e "\033[1;31m - The $TARFILE archive does not exist. \033[0;39m"
	    return 1
	  fi

	  (tar tf $TARFILE | grep "$ORIGTARDIR") &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo -e "\033[1;31m - The archive content is not correct. \033[0;39m"
	    return 1
	  fi
	  print_PASS
	  return 0
	}

	function grade_rsync {
	  printf "Checking for correct rsync backup. "

	  if [ ! -d $RSYNCDEST ]; then
	    print_FAIL
	    echo -e "\033[1;31m - The target directory $RSYNCDEST does not exist. \033[0;39m"
	    return 1
	  fi

	  rsync -avn $RSYNCSRC $RSYNCDEST &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo -e "\033[1;31m - Directory was not rsynced properly. \033[0;39m"
	    return 1
	  fi
	  print_PASS
	  return 0
}


#26 total objectives. Perhaps grader just counts the number of successful
#functions run and divide by 26 multiply by 100 and add a % to the end?
#with messages for 0-70 70-99 and 100% successful mastery.

###################################################################
###################################################################
################# Execute functions section #######################
###################################################################
###################################################################

function setup_script() {
	setup_servera
	setup_serverb
}

if [[ $# -eq 0 ]]
then
	help
	exit 0
	#  This should be replaced with a help function
fi

#We should uncomment grade functions one at a time to simplify testing.
function lab_grade() {
	grade_hostname
	grade_repos
	grade_shared_directory
	grade_facl
	grade_rsync
	grade_rootpw
	grade_users
	grade_httpd
	grade_tar
	grade_nfs
	grade_swap
	grade_vg
	grade_lv1
	grade_lvresize
	grade_findfiles
	grade_fileperms
	grade_performance
	grade_firewalld
	grade_php
	grade_vdo
	grade_stratis
}



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
