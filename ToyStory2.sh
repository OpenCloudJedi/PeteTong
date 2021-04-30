#This is the grader script for Server2 on the Toy Story Review
#!/bin/bash
########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

CHECKHOSTNAME="sunny.side.example.com"
PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME="conname"
ORIGINALCON="Wired\ Connection\ 1"

##### VG & LV #####
EXISTINGVGNAME="Lotso"
EXISTINGPESIZE="16M"
EXISTINGLVNAME="Gang"
EXISTINGLVSIZE="400M"
EXISTINGFSTYPE="xfs"
EXISTINGMOUNTPOINT="/VendingMachine"
EXISTINGFSLOW="200"
EXISTINGFSHIGH="300"
VGNAME="Lost"
PESIZE="8"
LVNAMEONE="Toys"
LVSIZEONEMIN="550"
LVSIZEONEMAX="650"
LVMMNTONE="/rescuer"
LVONETYPE="xfs"
LVNAMETWO="lv2"
SWAPPART1SIZE="+400"
LVPART2SIZE="+1G"
LVPART3SIZE="+512M"
SWAPBYTELOW="350000"
SWAPBYTEHIGH="450000"

##### Users and Groups #####
NEWPASS="suspenseful"
ROOTPASS="suspenseful"

##### Timezone #####
TIMEZONE="America/Los_Angeles"
TZSERVER="server classroom\.example\.com.*iburst"


##### Files and Directories #####
TARFILE="/root/libraries.tar.xz"
ORIGTARDIR="lib"  #for /var/lib This Variable works in the script if directed at the relative path
RSYNCSRC="/usr/share/"
RSYNCDEST="/shared_toys"
GREPFILESRC="/usr/share/dict/words"
GREPFILEDEST="/root/Fears"

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
}

function install_perl() {
    #perl is installed to support password grading functions.
    yum install perl -y
}

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
  if [ "${TUNED}" = "Current active profile: desktop" ]; then
    print_PASS
    return 0
  else
    print_FAIL
    echo -e "\033[1;31m - The tuning profile should be set to desktop.\033[0;39m"
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
vdo list | grep -q VDObox
  RESULT=$?
      if [ "${RESULT}" -ne 0 ]; then
                print_FAIL
                echo -e "\033[1;31m - VDO volume VDObox unavailable. \033[0;39m"
              return 1
      fi
vdo status --name=VDObox | grep -q "Logical size: 50G"
  RESULT=$?
      if [ "${RESULT}" -ne 0 ]; then
                print_FAIL
                echo -e "\033[1;31m - VDO volume VDObox doesn't have a logical size of 50G. \033[0;39m"
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
stratis pool list | grep -q Landfill
RESULT=$?
      if [ "${RESULT}" -ne 0 ]; then
                print_FAIL
                echo -e "\033[1;31m - Stratis pool Landfill does not exist. \033[0;39m"
              return 1
      fi
stratis filesystem | grep -q Incinerator
RESULT=$?
      if [ "${RESULT}" -ne 0 ]; then
                print_FAIL
                echo -e "\033[1;31m - Stratis filesystem called Incinerator was not found. \033[0;39m"
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

  read PART TYPE SIZE USED PRIO <<< $(swapon -s | grep -v /dev/sdb1 2>/dev/null | tail -n1 2>/dev/null) 2>/dev/null
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
  TESTUSER=forky
  TESTHOME=/bonnies_trash/${TESTUSER}
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

function lab_grade() {
	install_perl
  grade_rsync
	grade_rootpw
	grade_tar
	grade_nfs
	grade_swap
	grade_vg
	grade_lv1
	grade_lvresize
	grade_performance
	grade_vdo
	grade_stratis 
}
lab_grade
