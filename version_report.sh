#!/bin/bash

HostIpAddress=$(hostname -i)
NginxVersion=$(nginx -v 2>&1 | cut -d " " -f 3 | cut -d "/" -f 2)
DockerVersion=$(docker -v | cut -d " " -f3 | tr "," " ")
OSUname=$(uname)
EmailAddress=$(ENTER_EMAIL_ADDRESS)

cat <<EOF | /usr/bin/mail -s "$(date): Report on $(hostname)" $(EmailAddress)"
Docker Version: $DockerVersion
Nginx Version: $NginxVersion
OS Name: $OSUname
EOF
