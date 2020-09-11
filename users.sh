#!/bin/bash

# This script is to maske creating users and groups easier.

echo "What group would you like to make?"
        read GROUP
echo "What users would you like added to the $GROUP group? ie john jill marty"
        read USERS

        grep -q $GROUP /etc/group
        if [ $? = 0 ]; then
        echo "$GROUP already exists in /etc/group exiting"
                exit 1
        else
                groupadd $GROUP
                echo "Added the $GROUP group"
        fi
                for LOOP in $USERS; do
                useradd -G $GROUP $LOOP
                echo "The $LOOP user is created and part of the $GROUP group."
                id $LOOP
                echo ""
        done
echo "Would you like to add any users or groups to the sudoers file?"
        read SUDOANSWER
        if [ $SUDOANSWER = yes ]; then
                echo "Are you adding a user or group?"
                read UORG
                if [ $UORG = group ]; then
                        echo "what is the name of the group?"
                        read SUDOGROUP
                        echo "%${SUDOGROUP} ALL=(ALL) ALL" >> /etc/sudoers
                        echo "$SUDOGROUP added"
                elif [ $UORG = user ];then
                        echo "what is the name of the user?"
                        read SUDOUSER
                        echo "${SUDOUSER} ALL=(ALL) ALL" >> /etc/sudoers
                        echo "$SUDOUSER  user added to sudoers"
                fi
        else
                exit 0
        fi
                   
