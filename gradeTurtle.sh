#!/bin/bash

#  NAME
#	gradeTurtle.sh 
#
#  DESCRIPTION
#	This script was written to act as a grader for RedHat Homework#2

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
}

function grade_rsync_tmp {
  echo "Checking for correct rsync backup for /tmp"

  if [ ! -d /pizza ]; then
    print_FAIL
    echo " - The target directory /pizza does not exist."
    return 1
  fi

  rsync -avn /tmp /pizza &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - /tmp directory was not rsynced properly to /pizza."
    return 1
  fi
  print_PASS
  return 0
}



function grade_rsync_logs {
  echo "Checking for correct rsync backup for /var/log/"

  if [ ! -d /intelligence ]; then
    print_FAIL
    echo " - The target directory /intelligence does not exist."
    return 1
  fi

  rsync -avn /var/log/ /intelligence &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - /var/log directory was not rsynced properly to /intelligence"
    return 1
  fi
  print_PASS
  return 0
}


function grade_tarcompress_bzip {
  echo "Checking for correct bzip2 compressed archive"

  if [ ! -f /root/backup_dojo.tar.bzip2 ]; then
    print_FAIL
    echo " - The /root/backup_dojo.tar.bzip2 archive does not exist."
    return 1
  fi

  (tar tf /root/backup_dojo.tar.bzip2 | grep '^etc') &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The archive content is not correct."
    return 1
  fi
  print_PASS
  return 0
}



function grade_tarcompress_xz {
  echo "Checking for correct xz compressed archive"

  if [ ! -f /root/backup_logs.tar.xz ]; then
    print_FAIL
    echo " - The  archive /root/backup_logs.tar.xz does not exist."
    return 1
  fi

  (tar tf /root/backup_logs.tar.xz | grep 'log') &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The xz archive content is not correct."
    return 1
  fi
  print_PASS
  return 0
}


function grade_tz {
  echo "Checking for correct time and date settings"

  timedatectl | grep 'America/Los_Angeles' &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - The timezone was not set correctly."
    return 1
  fi
	echo "Checking to see if the nist.gov site has been added to the chrony config"
  if ! cat /etc/chrony.conf | grep -q 'server time-a-g\.nist\.gov'; then
    print_FAIL
    echo " - NTP is not set to synchronize from time-a-g.nist.gov"
    return 1
  fi

  print_PASS
}


function grade_hostname {
  echo "Checking that hostname is set to The_Ooze persistently"

  if ! hostnamectl | grep -q 'The_Ooze'; then
    print_FAIL
    echo " - Static hostname not configured corrrectly."
    return 1
  fi

  print_PASS

  return 0
} 
 
function grade_yumrepoAppstream {
  echo "Checking for correct Appstream yum repo setup"

  grep -R 'baseurl.*=.*download\.rockylinux.org\/pub\/rocky\/8\/BaseOS\/x86_64\/os' /etc/yum.repos.d/ &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - Check your Appstream yum repository again."
    return 1
  fi

  print_PASS
  return 0
}

function grade_yumrepoBaseOS {
  echo "Checking for correct BaseOS yum repo setup"

  grep -R 'baseurl.*=.*download\.rockylinux.org\/pub\/rocky\/8\/BaseOS\/x86_64\/os' /etc/yum.repos.d/ &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    print_FAIL
    echo " - Check your BaseOS yum repository again."
    return 1
  fi

  print_PASS
  return 0
}


grade_tarcompress_bzip
grade_tarcompress_xz
grade_rsync_tmp
grade_rsync_logs
grade_tz
grade_hostname
grade_yumrepoAppstream
grade_yumrepoBaseOS
