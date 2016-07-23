#!/bin/bash

# Update the OS
apt-get update
apt-get dist-upgrade -y

# Set the correct domain name in /etc/resolv.conf (openstack sets it to 'local', even if it has the complete FQDN)
domain=$(hostname -f | sed -n 's/[^.]*\.//p')
sed -i "s/local/$domain/g" /etc/resolv.conf

# Add puppetlabs repository
cd /tmp
wget http://apt.puppetlabs.com/puppetlabs-release-trusty.deb
dpkg -i puppetlabs-release-trusty.deb
apt-get update

# Install and start puppet
apt-get install puppet -y
sed -e 's/START=no/START=yes/g' -i /etc/default/puppet
service puppet start
