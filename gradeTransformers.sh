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


function grade_Autobot_makefiles {
  pad "Checking number of files in /Omega_one"  

  if (($(ls /Omega_one | grep log | wc -l) != 20)); then
    print_FAIL
    echo " - There are an incorrect number of log files in /Omega_one"
    return 1
  fi  

  print_PASS
  return 0
}


function grade_Decepticon_makefiles {
  pad "Checking number of files in /Trypticon"  

  if (($(ls /Trypticon | grep log | wc -l) != 20)); then
    print_FAIL
    echo " - There are an incorrect number of log files in Trypticon"
    return 1
  fi  

  print_PASS
  return 0
}
function grade_makefiles_Autobot_owner {
  pad "Checking file ownership in /Omega_one"  

  if (($(ls -l /Omega_one | grep 'Optimus' | wc -l) != 20)); then
    print_FAIL
    echo " - Optimus does not own 20 log files in /Omega_one"
    return 1
  fi  

  print_PASS
  return 0
}
function grade_makefiles_Decepticon_owner {
  pad "Checking file ownership in /Trypticon"  

  if (($(ls -l /Trypticon | grep 'Megatron' | wc -l) != 20)); then
    print_FAIL
    echo " - Megatron does not own 20 log files in /Trypticon"
    return 1
  fi  

  print_PASS
  return 0
}




function grade_Autobot_users {
  pad "Checking for correct user setup"

  grep 'Autobot:x:*' /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The Autobot group does not exist."
    return 1
  fi  

  for USER in Optimus BumbleBee JetFire Mirage; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER has not been created."
      return 1
    fi 
  done

  for USER in Optimus BumbleBee JetFire Mirage; do
    grep "Autobot:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER is not in the Autobot group."
      return 1
    fi  
  done


  if ! primary_group 'Optimus:' 'Optimus' ||
  ! primary_group 'BumbleBee:' 'BumbleBee' ||
  ! primary_group 'JetFire:' 'JetFire' ||
  ! primary_group 'Mirage:' 'Mirage'; then
	return 1
  fi	


  for USER in Optimus BumbleBee JetFire Mirage; do
    NEWPASS="Protect"
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


function grade_Decepticon_users {
  pad "Checking for correct user setup"

  grep 'Decepticon:x:*' /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The Decepticon group does not exist."
    return 1
  fi  

  for USER in Megatron StarScream Barricade Grimlock; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER has not been created."
      return 1
    fi 
  done

  for USER in Megatron StarScream Barricade Grimlock; do
    grep "Decepticon:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER is not in the Decepticon group."
      return 1
    fi  
  done


  if ! primary_group 'Megatron:' 'Megatron' ||
  ! primary_group 'StarScream:' 'StarScream' ||
  ! primary_group 'Barricade:' 'Barricade' ||
  ! primary_group 'Grimlock:' 'Grimlock'; then
	return 1
  fi	


  for USER in Megatron StarScream Barricade Grimlock; do
    NEWPASS="Destroy"
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

function grade_Autobot_shareddir {
  pad "Checking for correct Autobot shared directory"
  
  if [ ! -d /Omega_one ]; then
    print_FAIL
    echo " - The /Omega_one directory does not exist."
    return 1
  fi
  
  if [ $(stat -c %G /Omega_one) != "Autobot" ]; then
    print_FAIL
    echo " - /Omega_one does not have correct group ownership."
    return 1
  fi

  if [ $(stat -c %a /Omega_one) -ne 2770 ]; then
    print_FAIL
    echo " - /Omega_one does not have correct permissions."
    return 1
  fi

  print_PASS
  return 0
}

function grade_Decepticon_shareddir {
  pad "Checking for correct Decepticon shared directory"
  
  if [ ! -d /Trypticon ]; then
    print_FAIL
    echo " - The /Trypticon directory does not exist."
    return 1
  fi
  
  if [ $(stat -c %G /Trypticon) != "Decepticon" ]; then
    print_FAIL
    echo " - /Trypticon is not owned by the Decepticon group."
    return 1
  fi

  if [ $(stat -c %a /Trypticon) -ne 2770 ]; then
    print_FAIL
    echo " - /Trypticon does not have correct permissions."
    return 1
  fi

  print_PASS
  return 0
}




# end grading section

function lab_grade {
  FAIL=0
  grade_Autobot_makefiles || (( FAIL += 1 ))
  grade_Decepticon_makefiles || (( FAIL += 1 ))
  grade_makefiles_Autobot_owner || (( FAIL += 1 ))
  grade_makefiles_Decepticon_owner || (( FAIL += 1 ))
  grade_Autobot_users || (( FAIL += 1 ))
  grade_Decepticon_users || (( FAIL += 1 ))
  grade_Autobot_shareddir || (( FAIL += 1 ))
  grade_Decepticon_shareddir || (( FAIL += 1 ))
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
