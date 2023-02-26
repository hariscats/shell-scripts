#!/usr/bin/env bash

E_USEREXISTS=70
E_NOTROOT=130

if [ "$UID" -ne 0 ]
then
  echo "The user must be root to run this script."
  exit $E_NOTROOT
fi  

if [ $# -eq 0 ] 
then 
  echo "You did not pass any arguments"
  echo "Please pass in username and password"
fi

#test, if both argument are there
if [ $# -eq 2 ]; then
username=$1
pass=$2

	# Check if user already exists.
	grep -q "$username" /etc/passwd
	if [ $? -eq 0 ] 
	then	
	  echo "User $username already exists."
    echo "Please chose another username."
	  exit $E_USEREXISTS
	fi  


	useradd -p "$pass" -d /home/"$username" -m -g users -s /bin/bash "$username"

	echo "The Linux User account is setup"

else
        echo  "This script requires 2 arguments, you have given $#"
        echo  "You have to call the script $0 username and the pass"
fi

exit 0
