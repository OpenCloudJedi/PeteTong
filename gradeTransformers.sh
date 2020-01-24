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


function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}


function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}


function print_SUCCESS() {
  echo -e '\033[1;36mSUCCESS\033[0;39m'
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


