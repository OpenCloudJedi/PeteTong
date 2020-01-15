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
PESIZE="16M"
LVNAMEONE="lv1"
LVSIZEONEMIN="450"
LVSIZEONEMAX="510"
LVMMNTONE="/mountpoint1"
LVONETYPE="xfs"
LVNAMETWO="lv2"
SWAPPART1SIZE="+256M"
LVPART2SIZE="+1G"
LVPART3SIZE="+512M"
SWAPBYTELOW="500000"
SWAPBYTEHIGH="540000"

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
COLLABDIR=
COLLABGROUP=
TARFILE=
ORIGTARDIR=
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
function grade_httpd() {
	pad "Checking Apache service and SELINUX"
	if ! getenforce | grep -q 'Enforcing'; then
    print_FAIL
    echo " - selinux is not set to enforcing"
    return 1
  fi
	if ! systemctl status httpd.service &> /dev/null; then
    print_FAIL
    echo " - httpd.service is not running"
    return 1
  fi
  if ! systemctl status httpd 2> /dev/null | grep -q '^[[:space:]]*Loaded.*enabled'; then
    print_FAIL
    echo " - httpd.service not set to be started at boot"
    return 1
  fi
  if ! curl -v --silent localhost 2>&1 | grep -q 'You got it working'; then
    print_FAIL
    echo " - You are not serving the correct webpage"
    return 1
  fi
}

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
	function grade_users() {
		pad "Checking for correct user setup"

	  grep "${GROUPNAME}:x:*" /etc/group &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo " - The $GROUPNAME group does not exist."
	    return 1
	  fi

	  for USER in $SPECIALUSR $ARRAYUSERS; do
	    grep "$USER:x:.*" /etc/passwd &>/dev/null
	    RESULT=$?
	    if [ "${RESULT}" -ne 0 ]; then
	      print_FAIL
	      echo " - The user $USER has not been created."
	      return 1
	    fi
	  done

	  for USER in ${ARRAYUSERS}; do
	    grep "${GROUPNAME}:x:.*$USER.*" /etc/group &>/dev/null
	    RESULT=$?
	    if [ "${RESULT}" -ne 0 ]; then
	      print_FAIL
	      echo " - The user $USER is not in the $GROUPNAME group."
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
	    echo " - The user ${SPECIALUSR}s uid is not set to "$SUUID"
	    return 1
	  fi

	  for USER in ${ARRAYUSERS}; do
	    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
	    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
	    PERLCOMMAND="print crypt(\"${NEWPASS}\", \"\\\$6\\\$${SALT}\");"
	    NEWHASH=$(perl -e "${PERLCOMMAND}")

	    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
	      print_FAIL
	      echo " - The password for user $USER is not set to ${NEWPASS}"
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
	      echo " - The password for user $USER is not set to ${SPCLPWD}"
	      return 1
	    fi
	  done
	}


function grade_repos() {
	grep -R $YUMREPO1 /etc/yum.repos.d/ &>dev/null
	local result=$?

	if [[ "${result}" ne 0 ]]; then
		printf "Check your BaseOS yum repository again "
		print_FAIL
		return 1
	fi
	grep -R $YUMREPO2 /etc/yum.repos.d/ &>dev/null
	local result=$?

	if [[ "${result}" ne 0 ]]; then
		printf "Check your AppStream yum repository again "
		print_FAIL
		return 1
	fi
}

function grade_shared_directory() {
	if [ $(stat -c %G "$COLLABDIR") != "$COLLABGROUP" ]
	then
		printf "%s does not have correct group ownership " "$COLLABDIR"
		print_FAIL
		return 1
	fi

	if [ $(stat -c %a "$COLLABDIR") -ne 2770 ]
	then
		printf "%s does not have correct permissions " "$COLLABDIR"
		print_FAIL
		return 1
	fi
}

	function grade_fileperms() {
		pad "Checking permissions and ownership"

	  if ! [ -d ${COLLABDIR} ]; then
	    print_FAIL
	    echo " - Directory ${COLLABDIR} not found"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^# owner: root$' 2> /dev/null; then
	    print_FAIL
	    echo " - Ownership of ${COLLABDIR} not set to 'root'"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q "^# group: ${COLLABGROUP}$" 2> /dev/null; then
	    print_FAIL
	    echo " - Group ownership of ${COLLABDIR} not set to ${COLLABGROUP}"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^user::rwx$' 2> /dev/null; then
	    print_FAIL
	    echo " - User permissions not set to 'rwx' on ${COLLABDIR}"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^group::rwx$' 2> /dev/null; then
	    print_FAIL
	    echo " - Group permissions not set to 'rwx' on ${COLLABDIR}"
	    return 1
	  fi
	  if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^other::---$' 2> /dev/null; then
	    print_FAIL
	    echo " - Other permissions not set to no access on ${COLLABDIR}"
	    return 1
	  fi
		if ! getfacl ${COLLABDIR} 2> /dev/null | grep -q '^flags:-s-$' 2> /dev/null; then
	    print_FAIL
	    echo " - Special permissions (SETGID bit) not set on ${COLLABDIR}"
	    return 1
	  fi

	  print_PASS
	  return 0
	}

	function grade_findfiles() {
		  pad "Checking ${FINDDIR} has the correct files"

		  if [ ! -d ${FINDDIR} ]; then
		    print_FAIL
		    echo "The target directory ${FINDDIR} does not exist."
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FINDUSER}"; then
		    print_FAIL
		    echo "${FINDUSER}s files were not copied properly."
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE1}"; then
		    print_FAIL
		    echo "${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE1}"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE2}"; then
		    print_FAIL
		    echo "${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE2}"
		    return 1
		  fi

		  if ! ls ${FINDDIR} | grep -q "${FOUNDFILE3}"; then
		    print_FAIL
		    echo "${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE3}"
		    return 1
		  fi

			if ! ls ${FINDDIR} | grep -q "${FOUNDFILE4}"; then
		    print_FAIL
		    echo "${FINDUSER}s files were not copied properly. Did not find ${FOUNDFILE4}"
		    return 1
		  fi

		  print_PASS
		  return 0

	}
#function grade_grep() {}

	function grade_facl() {
		if [ ! -d $FACLDIRONE ]
  then
    printf "%s does not exist " "$FACLDIRONE"
    print_FAIL
    return 1
  else
  local facl=$(getfacl -p "$FACLONE" | "^user:"$FACLUSERONE":")
  local checkfacl="user:"$FACLUSERONE":rw"
  if ! [ "$facl" = "$checkfacl" ]; then
     printf "User $FACLUSERONE permission settings on %s are incorrect.." "$FACLONE"
     print_FAIL
     return 1
  fi
  fi

	if [ ! -d "FACLDIRTWO" ]
  then
    printf "%s does not exist " "$FACLTWO"
    print_FAIL
    return 1
  else
  local facl=$(getfacl -p "$FACLTWO" | "^user:"$FACLUSERTWO":")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     printf "User $FACLUSERTWO permission settings on %s are incorrect.." "$FACLDIRTWO"
     print_FAIL
     return 1
		 if [ ! -d "FACLDIRTWO" ]
  then
    printf "%s does not exist " "$FACLDIRTWO"
    print_FAIL
    return 1
  else
  local facl=$(getfacl -p "$FACLDIRTWO" | "^user:"$FACLUSERTWO":")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     printf "User permission settings on %s are incorrect.." "$FACLTWO"
     print_FAIL
     return 1
  fi
  fi
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
	      echo " - The password for user $USER is not set to ${ROOTPASS}"
	      return 1
	    fi
	  done
	}
	function grade_lvresize() {
		read LV VG A SIZE A <<< $(lvs --noheadings --units=m ${EXISTINGVGNAME} 2>/dev/null | grep ${EXISTINGLVNAME}) &> /dev/null
	  if [ "${LV}" != "${EXISTINGLVNAME}" ]; then
	    print_FAIL
	    echo " - No LV named ${EXISTINGLVNAME} found in VG ${EXISTINGVGNAME} we may have destroyed the existing data."
	    return 1
	  fi
	  SIZE=$(echo ${SIZE} | cut -d. -f1)
	  if  ! (( ${EXISTINGFSLOW} < ${SIZE} && ${SIZE} < ${EXISTINGFSHIGH} )); then
	    print_FAIL
	    echo " - Logical Volume ${EXISTINGLVNAME} is not the correct size."
	    return 1
	  fi
	}
	function grade_vg() {
		pad "Checking for new VG with correct PE size"

	  read VG A A A A SIZE A <<< $(vgs --noheadings --units=m ${VGNAME} 2>/dev/null) &> /dev/null
	  if [ "${VG}" != "$VGNAME" ]; then
	    print_FAIL
	    echo " - No Volume Group named ${VGNAME} found"
	    return 1
	  fi

	  if ! vgdisplay ${VGNAME} | grep 'PE Size' | grep -q "${PESIZE}"; then
	    print_FAIL
	    echo " - Incorrect PE size on volume group $VGNAME"
	    return 1
	  fi
	}
	function grade_lv1() {
		read LV VG A SIZE A <<< $(lvs --noheadings --units=m ${VGNAME} 2>/dev/null | grep ${LVNAMEONE}) &> /dev/null
	  if [ "${LV}" != "${LVNAMEONE}" ]; then
	    print_FAIL
	    echo " - No LV named ${LVNAMEONE} found in VG ${VGNAME}"
	    return 1
	  fi
	  SIZE=$(echo ${SIZE} | cut -d. -f1)
	  if  ! (( ${LVSIZEONEMIN} < ${SIZE} && ${SIZE} < ${LVSIZEONEMAX} )); then
	    print_FAIL
	    echo " - Logical Volume ${LVNAMEONE} is not the correct size."
	    return 1
	  fi
		read DEV TYPE MOUNTPOINT <<< $(df --output=source,fstype,target ${LVMMNTONE} 2> /dev/null | grep ${LVMMNTONE} 2> /dev/null) &> /dev/null
	  if [ "${DEV}" != "/dev/mapper/${VGNAME}-${LVNAMEONE}" ]; then
	    print_FAIL
	    echo " - Wrong device mounted on ${LVMMNTONE}"
	    return 1
	  fi
	  if [ "${TYPE}" != "${LVONETYPE}" ]; then
	    print_FAIL
	    echo " - Wrong file system type mounted on ${LVMMNTONE}"
	    return 1
	  fi
	  if [ "${MOUNTPOINT}" != "${LVMMNTONE}" ]; then
	    print_FAIL
	    echo " - Wrong mountpoint"
	    return 1
	  fi
	}
#function grade_lv2() {}
	function grade_performance() {
		pad "Checking performance profile"
		if [[ tuned-adm current -ne "virtual-guest" ]]; then
			print_FAIL
			echo "The tuning profile should be set to virtual-guest."
			return 1
		fi
	}
#function grade_vdo() {}
#function grade_stratis() {}
	function grade_swap() {
		pad "Checking for new swap partition"

	  NUMSWAPS=$(( $(swapon -s | wc -l) - 1 ))
	  if [ ${NUMSWAPS} -lt 1 ]; then
	    print_FAIL
	    echo " - No swap partition found. Did you delete the existing?"
	    return 1
	  fi
	  if [ ${NUMSWAPS} -gt 2 ]; then
	    print_FAIL
	    echo " - More than 2 swap partitions  found."
	    return 1
	  fi

	  read PART TYPE SIZE USED PRIO <<< $(swapon -s 2>/dev/null | tail -n1 2>/dev/null) 2>/dev/null
	  if [ "${TYPE}" != "partition" ]; then
	    print_FAIL
	    echo " - Swap is not a partition."
	  fi
	  if  ! (( ${SWAPBYTELOW} < ${SIZE} && ${SIZE} < ${SWAPBYTEHIGH} )); then
	    print_FAIL
	    echo " - Swap is not the correct size."
	    return 1
	  fi

	  if ! grep -q 'UUID.*swap' /etc/fstab; then
	    print_FAIL
	    echo " - Swap isn't mounted from /etc/fstab by UUID"
	    return 1
	  fi

	  print_PASS
	  return 0
	}
	function grade_nfs() {
		pad "Checking automounted home directories"
	  TESTUSER=production5
	  TESTHOME=/localhome/${TESTUSER}
	  DATA="$(su - ${TESTUSER} -c pwd 2>/dev/null)"
	  if [ "${DATA}" != "${TESTHOME}" ]; then
	    print_FAIL
	    echo " - Home directory not available for ${TESTUSER}"
	    return 1
	  fi
	  if ! mount | grep 'home-directories' | grep -q nfs; then
	    print_FAIL
	    echo " - ${TESTHOME} not mounted over NFS"
	    return 1
	  fi
	  	  print_PASS
	  return 0
	}

	function grade_tar() {
		pad "Checking for correct compressed archive"

	  if [ ! -f $TARFILE ]; then
	    print_FAIL
	    echo " - The $TARFILE archive does not exist."
	    return 1
	  fi

	  (tar tf $TARFILE | grep "$ORIGTARDIR") &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo " - The archive content is not correct."
	    return 1
	  fi
	  print_PASS
	  return 0
	}

	function grade_rsync {
	  pad "Checking for correct rsync backup"

	  if [ ! -d $RSYNCDEST ]; then
	    print_FAIL
	    echo " - The target directory $RSYNCDEST does not exist."
	    return 1
	  fi

	  rsync -avn $RSYNCSRC $RSYNCDEST &>/dev/null
	  RESULT=$?
	  if [ "${RESULT}" -ne 0 ]; then
	    print_FAIL
	    echo " - Directory was not rsynced properly."
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
#	setup_servera
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
	#grade_hostname
	#grade_repos
	#grade_shared_directory
	#grade_facl
	#grade_rsync
	#grade_rootpw
	#grade_users
	#grade_httpd
	#grade_tar
	#grade_nfs
	#grade_swap
	#grade_vg
	#grade_lv1
	#grade_lvresize
	#grade_findfiles
	#grade_fileperms
	#grade_performance
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
