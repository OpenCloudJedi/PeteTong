#!/bin/bash

# This is a setup and grader script written to compliment the
# Dark Knight HomeStudy guide.

# Variables
PROGNAME=DarkKnight.sh
FINDUSER="Riddler"
FINDDIR="/root/RiddleMeThis"
FINDFILES="/tmp/riddle,/var/log/me,/etc/this,/home/batman"
FOUNDFILE1="riddle"
FOUNDFILE2="me"
FOUNDFILE3="this"
FOUNDFILE4="batman"
CHECKHOSTNAME="DarkKnight"
HEROGROUPNAME="Heroes"
HEROARRAYUSERS=( Batman Robin Batgirl )
HEROPASS="IronManSucks"
VILLAINGROUPNAME="Villains"
VILLAINARRAYUSERS=( Joker Harley Catwoman )
VILLAINPASS="WhySoSerious"
RSYNCSRC1=/var/log/
RSYNCDEST1=/Clues
RSYNCSRC2=/etc
RSYNCDEST2=/BatComputer
TIMEZONE="America/Phoenix"
TZSERVER="server time\.google\.com.*iburst"
YUMREPO1="http://repo.eight.example.com/BaseOS"
YUMREPO2="http://repo.eight.example.com/AppStream"


# System functions

function setup() {
printf Verifying script has not been run before
grep 'Riddler' /etc/passwd
RESULT=$?
if [ "${RESULT}" -ne 1 ]; then
  echo -e "\033[1;31m - The Riddler user already exists. This script must have been run before.\033[0;39m"
  return 1
fi
  #Create $FINDUSER
echo "creating user: ${FINDUSER}";
useradd $FINDUSER;
#Create files to be found $FINDFILES
#Change Ownership of those files to the $FINDOWNER
for i in ${FINDFILES};do
        touch $i;
        chown $FINDUSER:$FINDUSER ${i};
done
yum install words -y &> /dev/null;
grep 'bat' /usr/share/dict/words > /tmp/BatGrep;
grep '^data' /usr/share/dict/linux.words > /tmp/LinuxWords;
}

# Grading functions

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
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

function grade_heroes() {
  printf "Checking for correct hero users and group setup. "

  grep "${HEROGROUPNAME}:x:*" /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The $HEROGROUPNAME group does not exist.\033[0;39m"
    return 1
  fi

  for USER in $HEROARRAYUSERS; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo -e "\033[1;31m - The user $USER has not been created.\033[0;39m"
      return 1
    fi
  done

  for USER in ${HEROARRAYUSERS}; do
    grep "${HEROGROUPNAME}:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo -e "\033[1;31m - The user $USER is not in the $HEROGROUPNAME group.\033[0;39m"
      return 1
    fi
  done

  if ! primary_group 'Batman:' 'Batman' ||
  ! primary_group 'Robin:' 'Robin' ||
  ! primary_group 'Batgirl:' 'Batgirl' ; then
  return 1
  fi

  for USER in ${HEROARRAYUSERS}; do
    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
    PERLCOMMAND="print crypt(\"${NEWPASS}\", \"\\\$6\\\$${SALT}\");"
    NEWHASH=$(perl -e "${PERLCOMMAND}")

    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
      print_FAIL
      echo -e "\033[1;31m - The password for user $USER is not set to ${HEROPASS}\033[0;39m"
      return 1
    fi
  done

  if [ ! -d /home/WayneManor ]; then
    echo -e "\033[1;31m - The homedirectory /home/WayneManor does not exist \033[3;39m"
    print_FAIL
    return 1
  fi
  grep "Batman:x:.*/home/WayneManor.*" /etc/passwd &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Batman does not have the homedirectory /home/WayneManor.\033[0;39m"
    return 1
  fi
  grep "Batgirl:x:.*"Barbara Gordon".*" /etc/passwd &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Batgirl does not have the comment "Barbara Gordon" set.\033[0;39m"
    return 1
  fi
    print_PASS
  return 0
}

function grade_villains() {
  printf "Checking for correct Villain users and group setup. "

  grep "${VILLAINGROUPNAME}:x:*" /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The $VILLAINGROUPNAME group does not exist.\033[0;39m"
    return 1
  fi

  for USER in $VILLAINARRAYUSERS; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo -e "\033[1;31m - The user $USER has not been created.\033[0;39m"
      return 1
    fi
  done

  for USER in ${VILLAINARRAYUSERS}; do
    grep "${VILLAINGROUPNAME}:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo -e "\033[1;31m - The user $USER is not in the $VILLAINGROUPNAME group.\033[0;39m"
      return 1
    fi
  done

  if ! primary_group 'Joker:' 'Joker' ||
  ! primary_group 'Harley:' 'Harley' ||
  ! primary_group 'Catwoman:' 'Catwoman' ; then
    print_FAIL
  return 1
  fi

  for USER in ${VILLAINARRAYUSERS}; do
    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
    PERLCOMMAND="print crypt(\"${NEWPASS}\", \"\\\$6\\\$${SALT}\");"
    NEWHASH=$(perl -e "${PERLCOMMAND}")

    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
      print_FAIL
      echo -e "\033[1;31m - The password for user $USER is not set to ${VILLAINPASS}\033[0;39m"
      return 1
    fi
  done

  grep "Catwoman:x:.*/bin/sh.*" /etc/passwd &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Catwoman does not have the shell set to /bin/sh.\033[0;39m"
    return 1
  fi
  chage -l Joker | grep "password must be changed" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Joker does not have the password set to be changed at first login.\033[0;39m"
    return 1
  fi
    print_PASS
  return 0
}

function grade_rsync1() {
  printf "Checking for correct rsync backup of /var/log. "

  if [ ! -d $RSYNCDEST1 ]; then
    print_FAIL
    echo -e "\033[1;31m - The target directory $RSYNCDEST1 does not exist. \033[0;39m"
    return 1
  fi

  rsync -avn $RSYNCSRC1 $RSYNCDEST1 &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - /var/log/ directory was not rsynced properly. \033[0;39m"
    return 1
  fi
  print_PASS
  return 0
}
function grade_rsync2() {
  printf "Checking for correct rsync backup of /etc. "

  if [ ! -d $RSYNCDEST2 ]; then
    print_FAIL
    echo -e "\033[1;31m - The target directory $RSYNCDEST2 does not exist. \033[0;39m"
    return 1
  fi

  rsync -avn $RSYNCSRC2 $RSYNCDEST2 &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - /etc directory was not rsynced properly. \033[0;39m"
    return 1
  fi
  print_PASS
  return 0
}

#function grade_time() {
#  timedatectl | grep $TIMEZONE &>/dev/null
#  RESULT=$?
#  if [ "${RESULT}" -ne 0 ]; then
#    print_FAIL
#    echo -e "\033[1;31m - The timezone has not been set to Phoenix time. \033[0;39m"
#    return 1
#  fi
#  grep "$TZSERVER" /etc/passwd &>/dev/null
#  RESULT=$?
#  if [ "${RESULT}" -ne 0 ]; then
#    print_FAIL
#    echo -e "\033[1;31m - The timezone has not been configured properly in /etc/chrony.conf\033[0;39m"
#    return 1
#  print_PASS
#  return 0
#
function grade_grep1() {
# Compare the two variables below using diff
  f1="/tmp/BatGrep"
  f2="/root/bat_files"
    if [ ! -f "$f2" ]; then
    echo -e "\033[1;31m - The ${f2} file does not exist \033[0;39m"
    print_FAIL
    return 1
  fi
  if diff -q $f1 $f2 &>/dev/null; then
    printf "The data has been grepped correctly in ${f2} "
    print_PASS
    return 0
  else
    echo -e "\033[1;31m - The ${f2} file has not been grepped correctly \033[0;39m"
    print_FAIL
    return 1
  fi
}
function grade_grep2() {
# Compare the two variables below using diff
  f1="/tmp/LinuxWords"
  f2="/root/data_words"
    if [ ! -f "$f2" ]; then
     echo -e "\033[1;31m - The ${f2} file does not exist \033[0;39m"
    print_FAIL
    return 1
  fi
  if diff -q $f1 $f2 &>/dev/null; then
    printf "The data has been grepped correctly in ${f2} "
    print_PASS
    return 0
  else
    echo -e "\033[1;31m - The ${f2} file has not been grepped correctly \033[0;39m"
    print_FAIL
    return 1
  fi
}

function grade_Heroes_shareddir() {
  pad "Checking for correct Heroes shared directory"

  if [ ! -d /BatCave ]; then
    print_FAIL
    echo -e "\033[1;31m - The /BatCave directory does not exist. \033[0;39m"
    return 1
  fi

  if [ $(stat -c %G /BatCave) != "Heroes" ]; then
    print_FAIL
    echo -e "\033[1;31m - /BatCave does not have correct group ownership.\033[0;39m"
    return 1
  fi

  if [ $(stat -c %U /BatCave) != "Batman" ]; then
    print_FAIL
    echo -e "\033[1;31m - /BatCave is not owned by Batman.\033[0;39m"
    return 1
  fi

  if [ $(stat -c %a /BatCave) -ne 2770 ]; then
    print_FAIL
    echo -e "\033[1;31m - /BatCave does not have correct permissions.\033[0;39m"
    return 1
  fi

  print_PASS
  return 0
}

function grade_Villains_shareddir() {
  printf "Checking for correct Heroes shared directory"

  if [ ! -d /ArkhamAsylum ]; then
    print_FAIL
    echo -e "\033[1;31m - The /ArkhamAsylum directory does not exist.\033[0;39m"
    return 1
  fi

  if [ $(stat -c %G /ArkhamAsylum) != "Villains" ]; then
    print_FAIL
    echo -e "\033[1;31m - /ArkhamAsylum does not have correct group ownership.\033[0;39m"
    return 1
  fi

  if [ $(stat -c %U /ArkhamAsylum) != "Joker" ]; then
    print_FAIL
    echo -e "\033[1;31m - /ArkhamAsylum is not owned by Joker.\033[0;39m"
    return 1
  fi

  if [ $(stat -c %a /ArkhamAsylum) -ne 2770 ]; then
    print_FAIL
    echo -e "\033[1;31m - /ArkhamAsylum does not have correct permissions.\033[0;39m"
    return 1
  fi

  print_PASS
  return 0
}

function grade_tarcompress_bzip() {
  echo "Checking for correct bzip2 compressed archive"

  if [ ! -f /root/shared_configs.tar.bz2 ]; then
    print_FAIL
    echo -e "\033[1;31m - The /root/shared_configs.tar.bz2 archive does not exist.\033[0;39m"
    return 1
  fi

  (tar tf /root/shared_configs.tar.bz2 | grep '^etc') &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The bzip2 archive does not contain /etc.\033[0;39m"
    return 1
  fi

  (tar tf /root/shared_configs.tar.bz2 | grep '^share') &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The bzip2 archive does not contain /usr/share.\033[0;39m"
    return 1
  fi
  print_PASS
  return 0
}

function grade_tarcompress_xz() {
  echo "Checking for correct xz compressed archive"

  if [ ! -f /root/logs.tar.xz ]; then
    print_FAIL
    echo -e "\033[1;31m - The  archive /root/logs.tar.xz does not exist.\033[0;39m"
    return 1
  fi

  (tar tf /root/logs.tar.xz | grep 'log') &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The xz archive content is not correct.\033[0;39m"
    return 1
  fi
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

  grep -R "gpgcheck=0" /etc/yum.repos.d/ &>/dev/null
  local result=$?

  if [[ "${result}" -ne 0 ]]; then
    print_FAIL
    echo -e '\033[1;31m - Could not find gpgcheck=0 line \033[0;39m'
    return 1
  fi

	printf "Your repositories have been setup correctly. Both appear to work. "
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

function grade_performance() {
  printf "Checking performance profile. "
  TUNED=$(tuned-adm active)
  if [ "${TUNED}" = "Current active profile: balanced" ]; then
    print_PASS
    return 0
  else
    print_FAIL
    echo -e "\033[1;31m - The tuning profile should be set to balanced.\033[0;39m"
    return 1
  fi
}


# Call functions

function lab_grade() {
        grade_hostname
        grade_heroes
        grade_villains
        grade_rsync1
        grade_rsync2
        grade_time
        grade_grep1
        grade_grep2
        grade_Heroes_shareddir
        grade_Villains_shareddir
        grade_tarcompress_bzip
        grade_tarcompress_xz
        grade_repos
        grade_findfiles
        grade_performance
}

case $1 in
	setup | --setup )
	#  Check if the file label has been created to prevent errors when running setup
		#if [ -e "$SETUPLABEL" ]
		#then
	#		printf "Setup has already been run on this system.\n"
	#	else
			setup
	#	fi
  	#sleep 4
		#reboot
	;;
	grade | --grade )
		lab_grade
	;;
	help | --help )
			printf "Proper usage is ./DarkKnight.sh setup or ./DarkKnight.sh grade depending on if you are setting things up or grading. \n"
	;;
	* )
		help
	;;
esac
