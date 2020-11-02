#!/bin/bash
  
ssh root@servera "
useradd -s /sbin/nologin Bilbo;
touch /tmp/Precious;
touch /bin/Ring;
touch /var/log/Precious2;
chown Bilbo:Bilbo /tmp/Precious;
chown Bilbo:Bilbo /bin/Ring;
chown Bilbo:Bilbo /var/log/Precious2;"
