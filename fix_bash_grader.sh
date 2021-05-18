#!/bin/bash
for server in servera serverb; do
ssh root@${server} "logger -p authpriv.warn "Failed password for manager1"
logger -p authpriv.warn "Failed password for sysadmin1"
logger -p authpriv.warn "Failed password for operator1""
done
