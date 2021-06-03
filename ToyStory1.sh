#Toy story script for Server1
#!/bin/bash

#This is the grader script for the tails from the script study guide.
#This one gets setup and run on servera.

########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

CHECKHOSTNAME="andys.room.example.com"
PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME="conname"
ORIGINALCON="ifcfg-eth1"



##### Users and Groups #####
ARRAYUSERS=( babyface ducky stinky_pete ) #  may end up changing from array
NEWPASS="moving"
ROOTPASS="moving"
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
SPECIALUSR="buzz"
SPCLPWD="moving"
SPECIALSH="/bin/sh"
SUUID="2100"
FINDUSER="Zurg"
FINDDIR="/root/Emperor"
FINDFILES="/tmp/ion-blaster,/var/log/evil,/etc/DarthVader.config,/home/galaxy"
FOUNDFILE1="ion-blaster"
FOUNDFILE2="evil"
FOUNDFILE3="DarthVader.config"
FOUNDFILE4="galaxy"

##### Timezone #####
TIMEZONE="America/Los_Angeles"
TZSERVER="server classroom\.example\.com.*iburst"

##### Yum #####
YUMREPO1='baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os'
YUMREPO2='baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os'

##### Files and Directories #####
HOMEDIRUSER=
USERDIR=
NOSHELLUSER=
COLLABDIR="/sid"
COLLABGROUP="Cannibals"
TARFILE="/root/tar.tar.gz"
ORIGTARDIR="lib"  #for /var/lib This Variable works in the script if directed at the relative path
RSYNCSRC="/boot"
RSYNCDEST="/rsync_destination"
FACLONE="/WoodysRescue"
FACLTWO="/WoodysRescue"
FACLUSERONE="babyface"
FACLUSERTWO="ducky"
GREPFILESRC="/usr/share/dict/words"
GREPFILEDEST="/root/roundup"
VIBECHECK="0"

##### Apache #####
DOCROOT="/Pizza_planet"


##### Firewall #####
VHOST_PORT="84"

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
}

function install_perl() {
    #perl is installed to support password grading functions.
    yum install perl -y &> /dev/null
}

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
  if ! curl -v --silent localhost:84 2>&1 | grep -q 'eternally'; then
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
  firewall-cmd --list-all | grep ${VHOST_PORT}/tcp &>/dev/null
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
    echo -e "\033[1;31m - Either no firewall rule for cockpit is present, or it is misconfigured. \033[0;39m"
    return 1
    	echo -e "\033[1;31m - Firewall rule for cockpit is not enabled. \033[0;39m"
  fi
	print_PASS
	return 0
}

	function grade_php() {
		printf "Checking to see that Inkscape is installed. "
	  inkscape --version &>/dev/null
	  RESULT=$?
          if [ "${RESULT}" -ne 0 ]; then
                  print_FAIL
                  echo -e "\033[1;31m - Inkscape was not installed. \033[0;39m"
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
	  if ! cat /etc/passwd | grep "$SPECIALUSR" | grep -q "$SPECIALSH"; then
     	     print_FAIL
      	     echo -e "\033[1;31m - The user ${SPECIALUSR}s shell is not set to ${SPECIALSH} \033[0;39m"
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
	if [ $(stat -c %G "$COLLABDIR") == "$COLLABGROUP" ]
	then
		if [ $(stat -c %a "$COLLABDIR") -ne 2770 ]
		then
			print_FAIL
			echo -e "\033[1;31m $COLLABDIR does not have correct permissions \033[0;39m"
			return 1
		
		elif [ $(stat -c %a "$COLLABDIR") -eq 2770 ]
		then
			print_PASS
			echo -e "\033[1;32m $COLLABDIR does have correct permissions \033[0;39m"
			print_PASS
			echo -e "Your shared directory has been correctly setup with correct ownership and permissions!"
		fi
	else
		print_FAIL
		echo  -e "\033[1;31m - $COLLABDIR does not have correct group ownership (${COLLABGROUP})  \033[0;39m"
		
	fi
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
		if [ ! -f $FACLONE ]
  then
    print_FAIL
    echo -e "\033[1;31m - File does not exist \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p /WoodysRescue | grep user:babyface:r--)
  local checkfacl="user:"$FACLUSERONE":r--"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - User $FACLUSERONE permission settings on $FACLONE are incorrect. \033[0;39m"
     return 1
  fi
  fi

	if [ ! -f "$FACLTWO" ]
  then
    print_FAIL
    echo -e "\033[1;31m - $FACLTWO does not exist. \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p "$FACLTWO" | grep "^user:"$FACLUSERTWO":---")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - User $FACLUSERTWO permission settings on $FACLTWO are incorrect. \033[0;39m"
     return 1
		 if [ ! -f "$FACLTWO" ]
  then
    print_FAIL
    echo -e "\033[1;31m - $FACLTWO does not exist. \033[0;39m"
    return 1
  else
  local facl=$(getfacl -p "$FACLTWO" | "^user:"$FACLUSERTWO":")
  local checkfacl="user:"$FACLUSERTWO":---"
  if ! [ "$facl" = "$checkfacl" ]; then
     print_FAIL
     echo -e "\033[1;31m - $FACLUSERTWO permission settings on $FACLTWO are incorrect. \033[0;39m"
     return 1
  fi
  fi
  fi
  fi
  	printf "The facls appear to have been configured correctly."
  	print_PASS
	return 0
  }


  #############################
  #######calling all functions######
  function lab_grade() {
  	install_perl
    grade_hostname
  	grade_repos
  	grade_shared_directory
  	grade_facl
  	grade_users
  	grade_httpd
  #	grade_tar 
  	grade_findfiles
  	grade_fileperms
  	grade_firewalld
  	grade_php
}


      lab_grade
