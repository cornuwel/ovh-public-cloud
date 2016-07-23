#!/bin/bash

if [ -f ~/.openrc ]
then
  source ~/.openrc
else
  echo "Missing ~/.openrc file"
  exit 1
fi

flavor="vps-ssd-1"
image="Ubuntu 14.04"

while getopts ":f:i:n:" opt; do
	case $opt in
		f)
			flavor=$OPTARG
			;;
		i)
			image=$OPTARG
			;;
		n)
			name=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done

flavor_id=$(nova flavor-list | grep " $flavor " | awk '{print $2;}')
if [[ -z $flavor_id ]]
then
	echo "Please pick a flavor (-f <flavor_name>)"
	nova flavor-list
	exit 1
fi

image_id=$(glance image-list | grep " $image " | awk '{print $2;}')
if [[ -z $image_id ]]
then
	echo "Please specify an image (-i <image_name>)"
	glance image-list
	exit 1
fi

if [[ -z $name ]]
then
	echo "Please specify a hostname (-n <hostname>)"
	exit 1
fi

nova boot --key-name julien-desk --flavor $flavor_id --image $image_id --user-data postInstall.sh $name

while true
do
	nova list | grep $name | grep Running && break
	sleep 5
done

tmpfile="/tmp/hosts.yaml"
echo -e "---\nhosts:" > $tmpfile
hosts=$(nova list | grep "Running")
while read -r host
do
	fqdn=$(echo $host | awk '{print $4;}')
	hostname=$(echo $fqdn | cut -d. -f1)
	ip=$(echo $host | awk -F"=" '{print $2}' | awk -F" " '{print $1}')
	echo "  $fqdn:" >> $tmpfile
	echo "    ip: \"$ip\"" >> $tmpfile
	echo "    host_aliases: \"$hostname\"" >> $tmpfile
done <<< "$hosts"

scp $tmpfile puppet:/etc/puppet/hieradata/hosts.yaml

while true
do
	ssh puppet 'sudo puppet agent --onetime --no-daemonize' && break
	sleep 5
done

ip=$(nova list | grep "$name" | awk -F"=" '{print $2}' | awk -F" " '{print $1}')

echo "Instance is running and doing its postInstall. Check it out: ssh admin@$ip"
