#!/bin/bash

# This is the setup and grader script for the 4th homework assignment.
CONTAINERUSER=Robin

### Setup Section ###
function lab_setup() {
  grep -q Robin /etc/passwd
  if [[ $? -ne 0 ]]; then
    useradd ${CONTAINERUSER}
    echo redhat | sudo passwd --stdin ${CONTAINERUSER}
  else
    echo "The Robin user already exists. This script must have been run before. Exiting."
    exit 1
  fi
  echo "Robin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
  dd if=/dev/urandom of=~/batmobile.img bs=1M count=256
  mkdir -p /home/${CONTAINERUSER}/.config/containers
  chown -R ${CONTAINERUSER}:${CONTAINERUSER} /home/${CONTAINERUSER}/.config
  cat > /home/${CONTAINERUSER}/.config/containers/registries.conf << EOF
  unqualified-search-registries = ['registry.lab.example.com']

[[registry]]
location = "registry.lab.example.com"
insecure = true
blocked = false
EOF
}

#  Colored PASS and FAIL for grading
function print_PASS() {
	echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
	echo -e '\033[1;31mFAIL\033[0;39m'
}

function grade_lvadd() {
  printf "Checking completion of Logical Volume addition. "
  read LV VG A SIZE A <<< $(lvs --noheadings --units=m Dark 2>/dev/null | grep Crusader) &> /dev/null
  if [ "${LV}" != "Crusader" ]; then
    print_FAIL
    echo -e "\033[1;31m - No LV named Crusader found in VG Dark. Go back and check your work. \033[0;39m"
    return 1
  fi
  SIZE=$(echo ${SIZE} | cut -d. -f1)
  if  ! (( 350 < ${SIZE} && ${SIZE} < 450 )); then
    print_FAIL
    echo -e "\033[1;31m - Logical Volume Crusader is not the correct size.\033[0;39m"
    return 1
  fi
}
function grade_vg() {
  printf "Checking for new VG with correct PE size"

  read VG A A A A SIZE A <<< $(vgs --noheadings --units=m ${VGNAME} 2>/dev/null) &> /dev/null
  if [ "${VG}" != "Dark" ]; then
    print_FAIL
    echo -e "\033[1;31m - No Volume Group named Dark found. \033[0;39m"
    return 1
  fi

  if ! vgdisplay Dark | grep 'PE Size' | grep -q "16"; then
    print_FAIL
    echo -e "\033[1;31m - Incorrect PE size on volume group Crusader. Should be set to 16M \033[0;39m"
    return 1
  fi
    print_PASS
              return 0
}

function grade_lv1() {
  printf "Checking the Logical Volume Setup."
  read LV VG A SIZE A <<< $(lvs --noheadings --units=m Dark 2>/dev/null | grep Knight) &> /dev/null
  if [ "${LV}" != "Knight" ]; then
    print_FAIL
    echo -e "\033[1;31m - No LV named Knight found in VG Dark \033[0;39m"
    return 1
  fi
  SIZE=$(echo ${SIZE} | cut -d. -f1)
  if  ! (( 1550 < ${SIZE} && ${SIZE} < 1650 )); then
    print_FAIL
    echo -e "\033[1;31m - Logical Volume Knight is not the correct size. Should be between 1550 and 1650Mb\033[0;39m"
    return 1
  fi
  read DEV TYPE MOUNTPOINT <<< $(df --output=source,fstype,target /Rises 2> /dev/null | grep /Rises 2> /dev/null) &> /dev/null
  if [ "${DEV}" != "/dev/mapper/Dark-Knight}" ]; then
    print_FAIL
    echo -e "\033[1;31m - Wrong device mounted on /Rises. \033[0;39m"
    return 1
  fi
  if [ "${TYPE}" != "xfs" ]; then
    print_FAIL
    echo -e "\033[1;31m - Wrong file system type mounted on /Rises. \033[0;39m"
    return 1
  fi
  if [ "${MOUNTPOINT}" != "/Rises" ]; then
    print_FAIL
    echo -e "\033[1;31m - Wrong mountpoint for /Rises. \033[0;39m"
    return 1
  fi
    print_PASS
              return 0
}

function grade_stratis() {
  systemctl is-enabled stratisd.service
  if [[ $? -ne 0 ]]; then
    print_FAIL
    echo -e "\033[1;31m - stratisd service is not enabled. \033[0;39m"
  fi
  grep -q x-systemd.requires=stratisd.service /etc/fstab
  if [[ $? -ne 0 ]]; then
    print_FAIL
    echo -e "\033[1;31m - Drive option missing from /etc/fstab. Make sure you add the systemd option \033[0;39m"
  fi
    stratis_pool_verify=$(stratis filesystem list | grep Justice | wc -l)
    if [[ $stratis_pool_verify -ne 1 ]]; then
      print_FAIL
      echo -e "\033[1;31m - Justice Stratis Pool doesn't exist. \033[0;39m"
    fi
    stratis_fs_verify=$(stratis filesystem list | grep League | wc -l)
    if [[ $stratis_fs_verify -ne 1 ]]; then
      print_FAIL
      echo -e "\033[1;31m - League Stratis Filesystem does not exist doesn't exist. \033[0;39m"
    fi
  stratis_mount_verify=$("mount" | grep Alliance | grep xfs | wc -l)
  if [[ $stratis_mount_verify -ne 1 ]]; then
    print_FAIL
    echo -e "\033[1;31m - League Stratis Filesystem is not mounted at /Alliance. \033[0;39m"
  fi
}

function grade_vdo() {
  echo " · Verifying the VDO volume"
  vdo_volume_verify=$(vdo status -n BatCave | grep -i size | grep Logical | grep 50G | wc -l)
  vdo_mount_verify=$(mount | grep /Garage | grep xfs | wc -l)
  if [ ${vdo_volume_verify} -eq 1 ] &&
     [ ${vdo_mount_verify} -eq 1 ]
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - Either vdo volume BatCave doesn't exist or isn't mounted at /Garage. \033[0;39m"
  fi

  echo " · Verifying the files in VDO volume on ${target}"
  if ${ssh} ${target} "test -s /Garage/batmobile.img.1" &&
     ${ssh} ${target} "test -s Garage/batmobile.img.2"
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - /Garage/batmobile.img.1 and /Garage/batmobile.img.2 do not exist. \033[0;39m"
  fi
}

function grade_container() {
  echo Checking that container tools are installed
  if rpm -q podman skopeo
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - container-tools module may not be installed properly. \033[0;39m"
  fi
  echo "Checking that webserve container exists"
  TMP_FILE="$(mktemp)"
  su - Robin -c 'podman inspect webserve' > "${TMP_FILE}"
  if [ $? -eq 0 ]
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - webserve container does not appear to exist. \033[0;39m"
  fi
  echo " · The container is using the correct image"
  if grep -q "registry.lab.example.com/rhel8/httpd-24" "${TMP_FILE}"
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - The container is not using the httpd-24 image. \033[0;39m"
  fi

  echo " · The container is using the correct image tag"
  if grep -q "registry.lab.example.com/rhel8/httpd-24:1-98" "${TMP_FILE}"
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - Wrong image tag selected. You should be running 1-98. \033[0;39m"
  fi
  echo " · The container host port is 8080"
  if grep -w 8080 "${TMP_FILE}" | grep -q '"hostPort"'
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - The host port is not 8080. \033[0;39m"
  fi
  if grep -w 80 "${TMP_FILE}" | grep -q '"containerPort"'
  then
    print_PASS
  else
    print_FAIL
    echo -e "\033[1;31m - The container port is not 80. \033[0;39m"
  fi
  echo " · The storage is mounted in /var/www/html"
 if grep -w "/var/www/html" "${TMP_FILE}" | grep -q '"Destination"'
 then
   print_PASS
 else
   print_FAIL
   echo -e "\033[1;31m - Persistant storage is not setup to go to /var/www/html. \033[0;39m"
 fi

 echo " · SELinux context is set for $(basename /home/Robin/DocRoot)"
 stat --format=%C /home/Robin/DocRoot | grep -q container_file_t
 if [ $? -eq 0 ]
 then
   print_PASS
 else
   print_FAIL
echo -e "\033[1;31m - The SELinux context is not correct on /home/Robin/DocRoot \033[0;39m"
 fi
    echo " · The systemd unit file exists for the container"
   if test -s /home/Robin/.config/systemd/user/container-webserve.service
   then
     print_PASS
   else
     print_FAIL
     echo -e "\033[1;31m - The sysetmd unit file does not appear to be in /home/Robin/systemd/user \033[0;39m"
   fi

      echo " · The systemd service for the container is enabled"
   if "id Robin"
   then
     if systemctl --user is-enabled container-webserve.service
     then
       print_PASS
     else
       print_FAIL
       echo -e "\033[1;31m - The container-webserve service does not appear to be enabled \033[0;39m"
     fi
   else
     print_FAIL
   fi
}

############Call Functions#################
case $1 in
  setup )
    lab_setup
    echo Machine is setup. You may begin your work.
    ;;
  grade )
    grade_vg
    grade_lvadd
    grade_lv1
    grade_vdo
    grade_stratis
    grade_container
    ;;
    * )
    echo "Usage is Batty.sh setup|grade"
    exit 0
    ;;
esac
