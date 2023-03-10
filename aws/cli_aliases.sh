# Get instance details
alias _aedi='aws ec2 describe-instances --output json'

# Replace with default ssh key
alias instance='aws ec2 run-instances --key-name stevens --image-id --output json'

# Prerequisite is to use a default subnet and SG
# Create a dual-stack instance
startInstance() {
	local ami=${1}
	local itype=${2:-"t3.micro"}
	
	subnet=$(aws ec2 describe-subnets --output json | jq -r '.Subnets[] | select( .Tags[]? | select(.Value == "dualstack")).SubnetId')
	sg=$(aws ec2 describe-security-groups --output json | jq -r '.SecurityGroups [] | select( .GroupName == "dualstack").GroupId')
	instance ${ami}				\
		--instance-type ${itype}	\
		--subnet-id "${subnet}"		\
		--security-group-ids "${sg}" |	\
		jq -r '.Instances[].InstanceId'
}

# Get hostname of instance ID
iname() {
	_aedi --instance-ids $@ | \
		jq -r ".Reservations[].Instances[].PublicDnsName"
}


# Report the hostname when we think it's up.
ec2wait() {
	aws ec2 wait instance-running --output json --instance-ids $@
	# "running" does not mean SSH is up, so give it a bit more time
	sleep 60
	echo "Instance $@ should now be up and running: "
	iname $@
}

# Use this to see which instances you currently
# have, regardless of their state.
alias instances='_aedi | jq -r ".Reservations[].Instances[].InstanceId"'

# Same thing, but printing the hostnames instead:
alias inames='_aedi | jq -r ".Reservations[].Instances[].PublicDnsName" | grep .'

# ...but often we only care about which instances are
# currently running:
alias running='_aedi --query Reservations[*].Instances[*].[InstanceId] --filters Name=instance-state-name,Values=running | jq -r ".[] | .[] | .[]"'

# Same thing, but printing hostnames isntead:
alias running-names='_aedi --query Reservations[*].Instances[*].[PublicDnsName] --filter Name=instance-state-name,Values=running | jq -r ".[] | .[] | .[]"'

# To get a listing of hostnames with instance-ids:
alias instance-id-and-names='_aedi | jq -r ".Reservations[].Instances[] | \"\(.PublicDnsName) \(.InstanceId)\""'

# Analogous to 'instance':
alias term-instance='aws ec2 terminate-instances --output json --instance-ids'

# When you want to kill all instances instead of going
# one-by-one.  We don't pipe into 'term-instance'
# because that may not be defined when xargs runs.
alias kill-all-instances='instances | xargs aws ec2 terminate-instances --instance-ids'

# To get console output:
alias console='aws ec2 get-console-output --output text --instance-id'

###
# Generic handling of volumes next:
###

# Create a new volume of size 1GB in us-east-1a unless
# specified otherwise, e.g., "newVolume 3 us-west-1"
newVolume() {
	aws ec2 create-volume --output json --size "${1:-1}" --availability-zone "${2:-us-east-1a}" | \
		jq -r ".VolumeId"
}

# We often attach just one volume to a given instance,
# so let's have a default function to save ourselves
# some typing.
attachVolume() {
	aws ec2 attach-volume --output json --volume-id "${1}" --instance-id "${2}" --device "${3:-/dev/sdf}"
}

# Same for detachingk, but we don't need to know the
# instance-id:
detachVolume() {
	local instance="$(aws ec2 describe-volumes --output json --volume-id "${1}" | \
				jq -r '.Volumes[].Attachments[].InstanceId')"
	if [ -z "${instance}" ]; then
		echo "Volume ${1} not attached to any instance?" >&2
		return
	fi
	aws ec2 detach-volume --output json --volume-id "${1}" --instance-id "${instance}" 
}

# Like 'instances', but for EBS volumes:
alias volumes='aws ec2 describe-volumes --output json | jq -r ".Volumes[].VolumeId"'

# Like 'term-instance', but for a single EBS volume:
alias del-volume='aws ec2 delete-volume --volume-id'

# Like 'killallInstances', but for EBS volumes:
alias kill-all-volumes='volumes | xargs -n 1 aws ec2 delete-volume --volume-id'

# A simple function to determine your current AWS bill
# for the calendar month.
#
# You need read access to the 'Cost Explorer Service';
# create an IAM policy that grants permissions to
# 'Read' and 'List' under "ce:".  (This may require
# additional "Anomaly" resources.)
awsCurrentBill() {
	local readonly start="$(date -r $(( $(date +%s) - (86400 * 30) )) +%Y-%m-%d)"
	local readonly end="$(date +%Y-%m-%d)"
	local num

	num=$(aws ce get-cost-and-usage					\
		--output json						\
		--time-period Start=${start},End=${end}			\
		--granularity MONTHLY					\
		--metrics UnblendedCost					\
		--query 'ResultsByTime[*].Total.[UnblendedCost]' |	\
		jq '.[][0].Amount  | tonumber*100 | round/100')

	if [ -z "${num}" ]; then
		return
	fi

	num=$(echo "0+${num}" | tr '\n' '+' | sed -e 's/\+$//' | xargs | bc)

	echo "AWS Billing Period ${start} - ${end}: \$${num}"
}

awsListResources() {
	local spacer=""
	local amis snapshots instances volumes

	amis=$(aws ec2 describe-images --owner self | 			\
		jq -r '.Images[] | "\(.ImageId) \(.BlockDeviceMappings[0].Ebs.SnapshotId) \"\(.Description)\""')
	if [ -n "${amis}" ]; then
		echo "You have the following AMIs:"
		echo "${amis}"
		spacer="
"
	fi

	snapshots=$(aws ec2 describe-snapshots --owner self |		\
			jq -r '.Snapshots[] | "\(.SnapshotId) \(.StartTime)"')
	if [ -n "${snapshots}" ]; then
		/bin/echo -n "${spacer}"
		echo "You have the following snapshots:"
		echo "${snapshots}"
		spacer="
"
	fi

	instances=$(aws ec2 describe-instances |			\
			jq -r '.Reservations[].Instances[] | "\(.InstanceId) (\(.State.Name)) \(.PublicDnsName)"')
	if [ -n "${instances}" ]; then
		/bin/echo -n "${spacer}"
		echo "You have the following instances:"
		echo "${instances}"
		spacer="
"
	fi

	volumes=$(aws ec2 describe-volumes |				\
			jq -r '.Volumes[] | "\(.VolumeId) \(.CreateTime) \(.Attachments[0].InstanceId)"')
	if [ -n "${volumes}" ]; then
		/bin/echo -n "${spacer}"
		echo "You have the following volumes:"
		echo "${volumes}"
	fi
}

###
# Specific instances
###

# I usually have aliases for the latest stable version
# of some common OS.  These generally change every few
# months when new releases are made available.

# https://wiki.debian.org/Cloud/AmazonEC2Image/Buster
# Log in as "admin".
alias start-debian='startInstance ami-031283ff8a43b021c'

# https://omniosce.org/setup/aws
# needs t3.micro; log in as "omnios"
alias start-omnios='startInstance ami-0669dd7b1ff900fcc'

# https://alt.fedoraproject.org/cloud/
# Log in as "fedora".
alias start-fedora='startInstance ami-08b4ee602f76bff79'

# https://cloud-images.ubuntu.com/locator/ec2/
# Log in as "ubuntu". 
alias start-ubuntu='startInstance ami-0b0ea68c435eb488d'

# https://www.freebsd.org/releases/13.1R/announce/
# Log in as "ec2-user".
alias start-freebsd='startInstance ami-0cf377776fddcf8ba'

# Log in as "root":
alias start-netbsd='startInstance ami-08b87fed21cce91cb t4g.nano'
alias start-netbsd-arm='start-netbsd'
# Log in as "ec2-user":
alias start-netbsd-amd64='startInstance ami-05ffda7ac6da57de1'
