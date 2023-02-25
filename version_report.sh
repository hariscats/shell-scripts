#!/usr/bin/env bash

# Basic script to get name and version of SW

HostIpAddress=$(hostname -i)
NginxVersion=$(nginx -v 2>&1 | cut -d " " -f 3 | cut -d "/" -f 2)
DockerVersion=$(docker -v | cut -d " " -f3 | tr "," " ")
OSUname=$(uname)

cat <<EOF
Docker Version: $DockerVersion
Nginx Version: $NginxVersion
OS Name: $OSUname
EOF

##### Python3 pip3 packages Version #####
echo "# python3 packages version"
{
    pip3 list
    echo "# python3 packages version" >> versions-$date.md
    pip3 list >> versions-$date.md
} || {
    echo "No python3"
}
