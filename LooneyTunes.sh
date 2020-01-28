#!/bin/bash

#**************************#
# written by Andras Marton #
#       Sept 03 2019       #
#                          #
#  http://placeonthe.net   #
# http://github.com/am401  #
#**************************#


#  Setup and grading script for Home Work exercise 3 
#+ to help gain experience with managing users, group,
#+ files and cron jobs.


#Pass/Fail colored words
function print_PASS() {
  echo -e '\033[1;32mPASS\033[0;39m'
}

function print_FAIL() {
  echo -e '\033[1;31mFAIL\033[0;39m'
}

# root access req for setup/grading
function check_root {
  if [[ "$EUID" -gt "0" ]] ; then
    echo "This script must be run as root!"
    exit 1
  fi
}

#*********#
#  Setup  #
#*********#

function create_users() {
  useradd -s /sbin/nologin Ralph
  useradd -s /sbin/nologin Sam
  useradd -s /sbin/nologin Gossamer
}

function ascii_art() {
cat > $(pwd)/\.marvins <<write_ASCII
angry           ||||||||||||,,
anGry            |WWWWWWWWW|W|||,
angry            |_________|~WWW||,
angRy             ~-_      ~_  ~WW||,
angry             __-~---__/ ~_  ~WW|,
anGry         _-~~         ~~-_~_  ~W
angry   _--~~~~~~~~~~___       ~-~_/
anGry  -                ~~~--_   ~_
angry |                       ~_   |
angRy |   ____-------___        -_  |
angry |-~~              ~~--_     - |
anGry  ~| ~--___________     |-_   ~_
aNgry    | \`~'/  \`~'_-~~  |  |~-_-
angry   _-~_~~~    ~~~   _-~  |  |
angRy  ---.--__         ---.-~  |
angry  | |    -~~-----~~| |    -
aNgry  |_|__-~          |_|__-~
write_ASCII
}

# Merge lines from .marvins & random generated text to /var/log/secure
function marvin() {
  while IFS= read -r file1 <&3
    do
      echo "$file1" >> /var/log/secure #  Must have quotes around var 
       for i in {1..5}; do             #+ to keep whitespace intact!
         local dateTime=$(date +"%a %d %T")  #  Add authentic log date+time stamp
         #  Generate random text to go inbetween each line of ascii_art()
         local randText=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 56 | head -n 1)
         echo "$dateTime localhost sshd[9152] $randText" >> /var/log/secure
       done
# Change location of input files if necessary
  done 3<$(pwd)/\.marvins
}

function hide_files() {
  mkdir /tmp/one
  mkdir /tmp/place
  touch /var/log/unicorn
  touch /tmp/platypus
  touch /usr/kraken
  touch /golden_squirrel
  touch /tmp/one/pixies
  touch /tmp/place/honest_people
  chown Gossamer /var/log/unicorn
  chown Gossamer /tmp/platypus
  chown Gossamer /usr/kraken
  chown Gossamer /golden_squirrel
  chown Gossamer /tmp/one/pixies
  chown Gossamer /tmp/place/honest_people
}

#************#
#   Grader   #
#************#

function grade_hidden_files() {

if [ ! -d /root/GossamerFiles ]; then
  printf "The target directory /root/GossamerFiles does not exist "
  print_FAIL
  return 1
fi

# Loop to check if all the files exist in /root/GossamerFiles
for file in unicorn platypus kraken golden_squirrel pixies honest_people; do
  if ! ls /root/GossamerFiles | grep -q "$file"; then
    printf "Gossamer's $file was not copied properly "
    print_FAIL
    return 1
  fi
done

  printf "You have found and moved all the files "
  print_PASS
  return 0
}

function grade_marvin() {
# Compare the two variables below using diff
  f1="$(pwd)/.marvins"
  f2="/root/VeryAngry.txt"
    if [ ! -f "$f2" ]; then
    printf "The VeryAngry.txt file does not exist "
    print_FAIL
    return 1
  fi
  if diff -q $f1 $f2 &>/dev/null; then
    printf "The data has been grepped correctly "
    print_PASS
    return 0
  else
    printf "The VeryAngry.txt file has not been grepped correctly "
    print_FAIL
    return 1
  fi
}

function grade_cronjob() {

# Check if crontabs exist for users:
  if [ ! -f /var/spool/cron/Ralph ]; then
    printf "crontab for Ralph does not exist "
    print_FAIL
    return 1
  fi

  if [ ! -f /var/spool/cron/Sam ]; then
    printf "crontab for Sam does not exist "
    print_FAIL
    return 1
  fi
# Variables set to compare strings
  cronRalph=$(crontab -u Ralph -l)
  chkRalph="0 18 * * 1-5 date >> /home/Ralph/MorninSam"
  cronSam=$(crontab -u Sam -l)
  chkSam="0 6 * * 1-5 date >> /home/Sam/MorninRalph"

  if [ "$cronRalph" != "$chkRalph" ]; then # compare set str against cron output
    printf "Cron job for Ralph has not been set correctly "
    print_FAIL
    return 1
  fi

  if [ "$cronSam" != "$chkSam" ]; then # again for user Sam
    printf "Cron job for Sam has not been set correctly "
    print_FAIL
    return 1
  fi

  printf "Cron job for Sam and Ralph have been setup correctly "
  print_PASS
  return 0
}

#  Function to be used within function grade_toons_group, this will use grep
#+ and awk to select group info
function grade_primary_group {
  groupid=$(grep $1 /etc/group | awk -F ":" '{print $(NF-1)}')
  primarygroupid=$(grep $2 /etc/passwd | awk -F ":" '{print $4}')
  if ! [ "$groupid" = "$primarygroupid" ]; then
    groupname=$(echo $1 | sed "s/:/./")
    printf "The user $2 is not in the primary group $groupname "
    print_FAIL
    return 1
  fi
}

function grade_toons_group {
# Check if toons group exists
  grep 'Toons:x:*' /etc/group &>/dev/null
  RESULT=$?
  if [ "${RESULT}" -ne 0 ]; then
    printf "The Toons group does not exist "
    print_FAIL
    return 1
  fi

#  Check if the user is within the Toons group using a for loop to
#+ cycle through all the users
  for USER in Bugs Daffy Taz; do
    getent group Toons | grep &>/dev/null "$USER"
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      printf "$USER is not in the Toons group "
      print_FAIL
      return 1
    fi
  done

  printf "All the users are part of the Toon group "
  print_PASS
  return 0

#  Call function grade_primary_group() to check if users still
#+ are in their own primary group
  if ! grade_primary_group 'Bugs:' 'Bugs' ||
  ! grade_primary_group 'Daffy:' 'Daffy' ||
  ! grade_primary_group 'Taz:' 'Taz'; then
    return 1 # error message will be printed using grade_primary_group()
  fi
}

function grade_check_users() {
# for loop to cycle through users ensuring they exist

  for USER in Bugs Daffy Taz; do
    grep "$USER:x:.*" /etc/passwd &>/dev/null
    RESULT=$?
    if [ "${RESULT}" -ne 0 ]; then
      printf "The user $USER has not been created "
      print_FAIL
      return 1
    fi
  done

#  The below algorithm will extract from /etc/shadow the salt for the user
#+ along with the encrypted hash. $PERLCOMMAND takes $NEWPASS and $SALT to
#+ create a hash to compare ($FULLHASH against $NEWHASH) - if the two match
#+ the password is the same
  for USER in Bugs Daffy Taz; do
    NEWPASS="Loony"
    FULLHASH=$(grep "^$USER:" /etc/shadow | cut -d: -f 2)
    SALT=$(grep "^$USER:" /etc/shadow | cut -d'$' -f3)
    PERLCOMMAND="print crypt(\"${NEWPASS}\", \"\\\$6\\\$${SALT}\");"
    NEWHASH=$(perl -e "${PERLCOMMAND}")
    if [ "${FULLHASH}" != "${NEWHASH}" ]; then
      printf "The password for user $USER is not set to ${NEWPASS} "
      print_FAIL
      return 1
    fi
  done

  printf "All user and group settings are correct "
  print_PASS
  return 0
}

function grade_mischief() {

  if [ ! -d /mischief ]; then
    printf "The /mischief directory does not exist "
    print_FAIL
    return 1
  fi

# Check that permissions for /mischief at 2770
  if [ $(stat -c %a /mischief) -ne 2770 ]; then
    printf "The /mischief directory does not have correct permissions "
    print_FAIL
    return 1
  fi

  if [ $(stat -c %G /mischief) != "Toons" ]; then
    printf "The Toons group does not own the /mischief directory "
    print_FAIL
    return 1
  fi

  printf "The directory permissions are set correctly "
  print_PASS
  return 0
}

function grade_facl() {

  if [ ! -d /mischief ]; then
    printf "Unable to check facl settings: /mischief directory does not exist "
    print_FAIL
    return 1
  fi

# Variables set so facl settings can be compared
  userTaz=$(getfacl -p /mischief | grep "^user:Taz:")
  chkTaz="user:Taz:---"
  defuserTaz=$(getfacl -p /mischief | grep "default:user:Taz:---")
  chkdefTaz="default:user:Taz:---"
  if ! [ "$userTaz" = "$chkTaz" ]; then
    printf "facl setting for Taz on /mischief is incorrect "
    print_FAIL
    return 1
  fi

  if ! [ "$defuserTaz" = "$chkdefTaz" ]; then
    printf "Default user facl setting for Taz on /mischief is incorrect "
    print_FAIL
    return 1
  fi

  printf "Settings on /mischief are correct "
  print_PASS
  return 0
}

function usage() {
  printf "Usage: looneyTunes.sh [ setup | grade ] [--help]"
  printf "\nTo setup the homework type:\t ./looneyTunes.sh setup\n"
  printf "To grade the homework type:\t ./looneyTunes.sh grade\n"
  printf "The option --help will bring up this menu\n"
}

function lab_grade() {
  # Set to 0 at start
  FAIL=0

  grade_hidden_files || (( FAIL += 1 ))
  grade_marvin || (( FAIL += 1 ))
  grade_cronjob || (( FAIL += 1 ))
  grade_toons_group || (( FAIL += 1 ))
  grade_check_users || (( FAIL += 1 ))
  grade_mischief || (( FAIL += 1 ))
  grade_facl || (( FAIL += 1 ))

  printf "++++++++++++++++++"
  printf "++ Overall result ++"
  printf "++++++++++++++++++\n"

  color_red=$(tput setaf 1)
  color_green=$(tput setaf 2)
  color_yellow=$(tput setaf 3)
  color_magenta=$(tput setaf 5)
  color_cyan=$(tput setaf 6)
  color_reset=$(tput sgr0)

  if [ ${FAIL} -eq 0 ]; then
    printf ${color_red}"%b" ".d8888b 888  888 .d8888b .d8888b .d88b. .d8888b .d8888b\n"${color_reset}
    printf ${color_green}"%b" "88K     888  888d88P\"   d88P\"   d8P  Y8b88K     88K\n"${color_reset}
    printf ${color_yellow}"%b" "\"Y8888b.888  888888     888     88888888\"Y8888b.\"Y8888b.\n"${color_reset}
    printf ${color_magenta}"%b"  "     X88Y88b 888Y88b.   Y88b.   Y8b.         X88     X88\n"${color_reset}
    printf ${color_cyan}"%b" "88888P' \"Y88888 \"Y8888P \"Y8888P \"Y8888  88888P' 88888P'\n"${color_reset}

    printf "\nCongratulations! You've passed all the tests........"
    print_PASS
  else
    printf "You have failed ${FAIL} tests, please check your work and try again "
    print_FAIL
  fi
}

# Before checking for command line arguments check if script is run as root
check_root

# If no command line arguments are provided, print usage
if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# Main body of script
case $1 in
  setup )
        create_users
        ascii_art
        marvin
        hide_files
        echo "Setup complete. Please refer to instructions to begin work"
        ;;
  grade )
        lab_grade
        ;;
  --help )
        usage
        ;;
      * )
        usage
        ;;
esac
