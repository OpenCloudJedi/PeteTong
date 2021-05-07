#!/bin/bash
# NAME
#     grademe - grading script for RedHat Homework #1
#
# SYNOPSIS
#     grademe (--help)
#
#     This script only works on desktopX.example.com.
#
# DESCRIPTION
#     This script, based on singular argument, either does setup or
#     grading for the Transformers homework lab.
#
# Initialize and set some variables
MYHOST=""
CMD=""
DEBUG='true'
RUN_AS_ROOT='true'
# Source library of functions
LOG_FACILITY=local0
LOG_PRIORITY=info
LOG_TAG="${0##*/}"
DEBUG=false
ERROR_MESSAGE="Error running script. Contact your instructor if you continue \
to see this message."
PACKAGES=( bash )
# paths
LOGGER='/usr/bin/logger'
RPM='/bin/rpm'
SUDO='/usr/bin/sudo'
# Export LANG so we get consistent results
# For instance, fr_FR uses comma (,) as the decimal separator.
export LANG=en_US.UTF-8
# Read in GLS parameters if available
[ -r /etc/rht ] && . /etc/rht
# Set up exit handler (no need for user to do this)
trap on_exit EXIT
function log {
if [[ ${#1} -gt 0 ]] ; then
    $LOGGER -p ${LOG_FACILITY}.${LOG_PRIORITY} -t $LOG_TAG -- "$1"
else
    while read data ; do
        $LOGGER -p ${LOG_FACILITY}.${LOG_PRIORITY} -t $LOG_TAG -- "$1" "$data"
    done
fi
}
function debug {
if [[ ${#1} -gt 0 ]] ; then
    msg="$1"
    if [[ "$DEBUG" = "true" ]] ; then
        echo "$msg"
    fi
    log "$msg"
else
    while read data ; do
        if [[ "$DEBUG" = "true" ]] ; then
            echo "$data"
        fi
        log "$data"
    done
fi
}
function on_exit {
status="$?"
if [[ "$status" -eq "0" ]] ; then
    exit 0
else
    DEBUG=true
    debug "$ERROR_MESSAGE"
    exit "$status"
fi
}
function check_root {
if [[ "$EUID" -gt "0" ]] ; then
    log 'Not running run as root = Fail'
    ERROR_MESSAGE='This script must be run as root!'
    exit 1
fi
}
function check_packages {
for package in ${PACKAGES[@]} ; do
    if $RPM -q $package &>/dev/null ; then
        continue
    else
        ERROR_MESSAGE="Please install $package and try again."
        exit 2
    fi
done
}
function confirm {
read -p "Is this ok [y/N]: " userInput
case "${userInput:0:1}" in
    "y" | "Y")
        return
        ;;
    *)
        ERROR_MESSAGE="Script aborted."
        exit 3
        ;;
esac
}
function check_host {
if [[ ${#1} -gt 0 ]]; then
    if [[ "$1" == "${HOSTNAME:0:${#1}}" ]]; then
        return
    else
        ERROR_MESSAGE="This script must be run on ${1}."
        exit 4
    fi
fi
}
function check_tcp_port {
if [[ ${#1} -gt 0 && ${#2} -gt 0 ]]; then
    # Sending it to the log always returns 0
    ($(echo "brain" >/dev/tcp/$1/$2)) && return 0
fi
return 1
}
function wait_tcp_port {
if [[ ${#1} -gt 0 && ${#2} -gt 0 ]]; then
    # Make sure it is pingable before we attempt the port check
    echo
    echo -n "Pinging $1"
    until `ping -c1 -w1 $1 &> /dev/null`;do
        echo -n "."
        sleep 3
    done
    iterations=0
    echo
    echo 'You may see a few "Connection refused" errors before it connects...'
    sleep 10
    until [[ "$remote_port" == "smart" || $iterations -eq 30 ]]; do
        ($(echo "brain" >/dev/tcp/$1/$2) ) && remote_port="smart" || remote_port="dumb"
        sleep 3
        iterations=$(expr $iterations + 1)
    done
    [[ $remote_port == "smart" ]] && return 0
fi
return 1
}
function push_sshkey {
if [[ ${#1} -gt 0 ]]; then
    rm -f /root/.ssh/known_hosts
    rm -f /root/.ssh/.labtoolkey
    rm -f /root/.ssh/.labtoolkey.pub
    (ssh-keygen -q -N "" -f /root/.ssh/.labtoolkey) || return 1
    (/usr/local/lib/labtool-installkey /root/.ssh/.labtoolkey.pub $1) && return 0
fi
return 1
}
function get_X {
  if [[ -n "${RHT_ENROLLMENT}" ]] ; then
    X="${RHT_ENROLLMENT}"
    MYHOST="${RHT_ROLE}"
  elif hostname -s | grep -q '[0-9]' ; then
    X="$(hostname -s | grep -o '[0-9]*')"
    MYHOST="$(hostname -s | grep -o '[^0-9]*')"
  else
    # If the short hostname does not have a number, it is probably localhost.
    return 1
  fi
  SERVERX="server${X}.example.com"
  DESKTOPX="desktop${X}.example.com"
  # *** The following variables are deprecated. Do not use them.
# TWO_DIGIT_X="$(printf %02i ${X})"
# TWO_DIGIT_HEX="$(printf %02x ${X})"
# LASTIPOCTET="$(hostname -i | cut -d. -f4)"
# # IPOCTETX should match X
# IPOCTETX="$(hostname -i | cut -d. -f3)"
  return 0
}
function get_disk_devices {
  # This functions assumes / is mounted on a physical partition,
  #   and that the secondary disk is of the same type.
  PDISK=$(df | grep '/$' | sed 's:/dev/\([a-z]*\).*:\1:')
  SDISK=$(grep -v "${PDISK}" /proc/partitions | sed '1,2d; s/.* //' |
          grep "${PDISK:0:${#PDISK}-1}.$" | sort | head -n 1)
  PDISKDEV=/dev/${PDISK}
  SDISKDEV=/dev/${SDISK}
}
function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}
function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}
function print_SUCCESS() {
  echo -e '\033[1;36mSUCCESS\033[0;39m'
}
# Additional functions for this shell script
function print_usage {
  cat << EOF
This script controls the grading of this lab.
Usage: grademe
       grademe -h|--help
EOF
}
function pad {
  PADDING="..............................................................."
  TITLE=$1
  printf "%s%s  " "${TITLE}" "${PADDING:${#TITLE}}"
}
 function install_perl {
   yum install perl -y
 }
function grade_Avengers_users {
  pad "Checking for correct user setup"
  grep 'Avengers:x:*' /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The Avengers group does not exist."
    return 1
  fi
  for USER in IronMan Hulk Loki Vision Thor; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER has not been created."
      return 1
    fi
  done
  for USER in IronMan Hulk Vision Thor; do
    grep "Avengers:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER is not in the Avengers group."
      return 1
    fi
  done
  if ! primary_group 'IronMan:' 'IronMan' ||
  ! primary_group 'Hulk:' 'Hulk' ||
  ! primary_group 'Vision:' 'Vision' ||
  ! primary_group 'Thor:' 'Thor'; then
	return 1
  fi
  for USER in IronMan Hulk Loki Vision Thor; do
    NEWPASS="Marvel"
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
  print_PASS
  return 0
}
#natasha - customized function to check for primary group membership
function primary_group {
	groupid=$(grep $1 /etc/group | awk -F ":" '{print $(NF-1)}')
        primarygroupid=$(grep $2 /etc/passwd | awk -F ":" '{print $4}')
        if ! [ "$groupid" = "$primarygroupid" ]; then
            print_FAIL
	    groupname=$(echo $1 | sed "s/:/./")
            echo " - The user $2 is not in the primary group $groupname"
            return 1
        fi
}
function grade_Avengers_shareddir {
  pad "Checking for correct Avengers shared directory"
  if [ ! -d /Stark/Tower ]; then
    print_FAIL
    echo " - The /Stark/Tower directory does not exist."
    return 1
  fi
  if [ $(stat -c %G /Stark/Tower) != "Avengers" ]; then
    print_FAIL
    echo " - /Stark/Tower does not have correct group ownership."
    return 1
  fi
  if [ $(stat -c %a /Stark/Tower) -ne 2770 ]; then
    print_FAIL
    echo " - /Stark/Tower does not have correct permissions."
    return 1
  fi
  print_PASS
  return 0
}
function grade_soft_link {
 pad 'Checking for correct symbolic link'
 RESULT=$(find /home/IronMan/ -type l)
  if [ "${RESULT}" = /home/IronMan/Work ]; then
    print_PASS
   else
print_FAIL
	   echo "The /home/IronMan/Work symbolic link does not exist." 
    return 1
  fi
}
function grade_httpd_service {
pad 'Checking httpd service'
if ! systemctl status httpd.service &> /dev/null; then
    print_FAIL
    echo "- httpd.service is not running."
    return 1
  fi
  if ! systemctl status httpd 2> /dev/null | grep -q '^[[:space:]]*Loaded.*enabled'; then
    print_FAIL
    echo "- httpd.service not set to be started at boot."
    return 1
    else
	    print_PASS
  fi
}
function grade_ssh {
	pad "Checking for SSH keys"
	if [ ! -f "/home/IronMan/.ssh/id_rsa.pub" ]; then
		print_FAIL
	echo "You don't have your id_rsa.pub file. Did you do ssh-keygen?"
	return 1
  fi
	if [ ! -f "/home/IronMan/.ssh/id_rsa" ]; then
		print_FAIL
	echo "Your private key is not in /home/IronMan/.ssh"
	return 1
else
	print_PASS
  fi
}
function grade_journal {
	pad 'Checking for persistent journal.'
	RESULT=$(grep Storage=persistent /etc/systemd/journald.conf)
	if [[ "${RESULT}" = Storage=persistent ]]; then
		print_PASS
	else
	print_FAIL
	echo " - Persistent Journal is not configured."
	return 1
fi
}
function grade_tz {
  pad 'Checking for correct time and date settings'
  timedatectl | grep 'America/Mexico_City'
  if [[ $? = 1 ]]; then
    print_FAIL
    echo " - The timezone was not set correctly."
    return 1
    else
	    print_PASS
  fi
  echo "Checking if the time.google site has been added to the chrony config"
  if ! cat /etc/chrony.conf | grep -q 'server time.google.com'; then
    print_FAIL
    echo " - NTP is not set to synchronize from time.google.com"
    return 1
    else
	    print_PASS
  fi
}
install_perl
# end grading section
function lab_grade {
  FAIL=0
  grade_Avengers_users || (( FAIL += 1 ))
  grade_Avengers_shareddir || (( FAIL += 1 ))
  grade_soft_link || (( FAIL += 1 ))
  grade_httpd_service || (( FAIL += 1 ))
  grade_ssh || (( FAIL += 1 ))
  grade_journal || (( FAIL += 1 ))
  grade_tz || (( FAIL += 1 ))
  echo
  pad "Overall result"
  if [ ${FAIL} -eq 0 ]; then
    print_PASS
    echo "Congratulations! You've passed all tests."
  else
    print_FAIL
    echo "You failed ${FAIL} tests, please check your work and try again."
  fi
}
# Main area
# Check if to be run as root (must do this first)
if [[ "${RUN_AS_ROOT}" == 'true' ]] && [[ "${EUID}" -gt "0" ]] ; then
  if [[ -x /usr/bin/sudo ]] ; then
    ${SUDO:-sudo} $0 "$@"
    exit
  else
    # Fail out if not running as root
    check_root
  fi
fi
get_X
# Branch based on short (without number) hostname
lab_grade 'desktop'
