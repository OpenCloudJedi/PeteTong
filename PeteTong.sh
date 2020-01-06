#!/bin/bash
#  Template started Sunday 5th January 2020
#  NAME
#	PeteTong.sh - however this can be changed to meet user
#	specific needs!
#
#  DESCRIPTION
#	This script was written to act as a template to be used with
#	instructing students who want to learn and explore Linux and
#	better understand how to manage the environment. The template
#	style should help verify the script so that instructions can
#	be managed to suit the educator/student need and to be able to
#	utilize themes.
#
#	Currently the script has been configured and tested in the RHEL 
#	classroom environment and should run there properly. This may be 
#	adapted adapted to work in other environments in later versions.
#
#  SETUP
#	The script should be able to run without any other major
#	dependancies and anything it would require for grading the
#	setup side should pull. The current version does NOT require
#	an internet connection to setup.
#
#	As the script deals with partitioning the device, it is
#	recommended to be run on a virtual machine so as to not cause
#	issues for the host.
#
#	The script itself can be renamed to match the theme of the
#	instructions. To run the setup:
#	# ./PeteTong.sh setup
#	The grade the work:
#	# ./PeteTong grade
#
#  Export LANG so we get consistent results throughout script
export LANG=en_US.UTF-8

########################################################
#  Global Variables ####################################
#  Alter these to suit your personal guide #############
########################################################

CHECKHOSTNAME=
PROGNAME=$0
SETUPLABEL="/tmp/.setuplabel"

##### Network Settings #####
CONNAME=
ORIGINALCON=

##### VG & LV #####
VGNAME=
PESIZE=
LVNAMEONE=
LVSIZEONEMIN=
LVSIZEONEMAX=
LVMMNTONE=
LVONETYPE=
LVNAMETWO=
LVSIZETWOMIN=
LVSIZETWOMAX=
LVMMNTTWO=
LVTWOTYPE=
LVRESIZE=
SETVGNAME=
SETLVNAME=
SETMNT=

##### Users and Groups #####
GROUPNAME=
ARRAYUSERS=( user1 user2 user3 user4 )
NEWPASS=
ROOTPASS=
#  If using a special user for facls or etc its details can be set here
#  along with a UID for the user
SPECIALUSR=
SPCLPWD=
SUUID=
CHAGEUSER1=
CHAGEUSER2=
PASSWDEXP="Password expires"

##### Timezone #####
TIMEZONE="America/"
TZSERVER="server classroom\.example\.com.*iburst"

##### Yum #####
YUMREPO1=
YUMREPO2=

##### Files and Directories #####
HOMEDIRUSER=
USERDIR=
NOSHELLUSER=
COLLABDIR=
COLLABGROUP=
TARFILE=
ORIGTARDIR=
RSYNCSRC=
RSYNCDEST=
FACLDIRONE=
FACLDIRTWO=
FACLUSERONE=
FACLUSERTWO=

##### Cron #####
CRONUSER=
CHKCRONNUMS=
CHKCRONDAYS=


###################################################################
###################################################################
################# Functions section ###############################
###################################################################
###################################################################
