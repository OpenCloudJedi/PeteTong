#!/bin/bash


function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}


function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}

function pad {
  PADDING="..............................................................."
  TITLE=$1
  printf "%s%s  " "${TITLE}" "${PADDING:${#TITLE}}"
}
 function install_perl {
   sudo yum install perl -y
 }

function grade_users {
  pad "Checking for correct user setup"

  grep 'Fantastic4:x:*' /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The Fantastic4 group does not exist."
    return 1
  fi

  for USER in Susan Reed Johnny Ben; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER has not been created."
      return 1
    fi
  done

  for USER in Susan Reed Johnny Ben; do
    grep "Fantastic4:x:.*$USER.*" /etc/group &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      print_FAIL
      echo " - The user $USER is not in the Fantastic4 group."
      return 1
    fi
  done


  if ! primary_group 'Susan:' 'Susan' ||
  ! primary_group 'Johnny:' 'Johnny' ||
  ! primary_group 'Reed:' 'Reed' ||
  ! primary_group 'Ben:' 'Ben'; then
	return 1
  fi


  for USER in Susan Reed Johnny Ben; do
    NEWPASS="Invisible"
    FULLHASH=$(sudo grep "^$USER:" /etc/shadow | cut -d: -f 2)
    SALT=$(sudo grep "^$USER:" /etc/shadow | cut -d'$' -f3)
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

function grade_password_aging {
  pad "Checking for correct password aging policies"
  sudo chage -l Susan | grep "password must be changed" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Susan does not have the password set to be changed at first login.\033[0;39m"
    return 1
  fi
  sudo chage -l Reed | grep "password must be changed" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Reed does not have the password set to be changed at first login.\033[0;39m"
    return 1
  fi
  sudo chage -l Johnny | grep "password must be changed" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Johnny does not have the password set to be changed at first login.\033[0;39m"
    return 1
  fi
  sudo chage -l Ben | grep "password must be changed" &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo -e "\033[1;31m - The user Ben does not have the password set to be changed at first login.\033[0;39m"
    return 1
  fi
    print_PASS
  return 0
}

install_perl

# end grading section

function lab_grade {
  FAIL=0
  grade_users || (( FAIL += 1 ))
  grade_password_aging || (( FAIL += 1 ))
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


# Branch based on short (without number) hostname
lab_grade 
