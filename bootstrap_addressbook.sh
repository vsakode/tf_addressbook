#!/bin/bash

apt-get install curl -y
if [[ ! -d /opt/chef ]]; then curl -L https://www.opscode.com/chef/install.sh | bash ; fi

# We want to use the instance ID in the name, but strip the hyphen from the instance id
INSTANCE_ID="$(curl -s http://169.254.169.254/latest/meta-data/instance-id | sed 's/\-//g')"
CHEF_SERVER="54.158.123.106"
NODE_NAME="addressbook-prod-$INSTANCE_ID"
CHEF_ENVIRONMENT=addressbook-prod
CHEF_RUNLIST=recipe[addressbook::default]

# set hostname
echo $NODE_NAME > /etc/hostname
hostname $NODE_NAME
echo "127.0.0.1 $NODE_NAME.$DOMAIN $NODE_NAME" >> /etc/hosts

# make chef-client config dir and fix permissions
echo "Creating /etc/chef"
sudo mkdir -p /etc/chef
sudo chmod 0755 /etc/chef
echo "Copying chef certificate into place"
echo "-----BEGIN RSA PRIVATE KEY-----
**************************************
*************************************
-----END RSA PRIVATE KEY-----" >> /etc/chef/validation.pem

chmod 644 /etc/chef/validation.pem

# create a minimal chef-client config file
sudo touch /etc/chef/client.rb
sudo chown ubuntu /etc/chef/client.rb

echo "Creating chef-client config file"
echo 'log_level :info' >> /etc/chef/client.rb
echo 'log_location STDOUT' >> /etc/chef/client.rb
echo "chef_server_url \"https://${CHEF_SERVER}/\"" >> /etc/chef/client.rb
echo "validation_client_name \"chef-validator\"" >> /etc/chef/client.rb
echo "node_name \"${NODE_NAME}\"" >> /etc/chef/client.rb
echo "environment \"${CHEF_ENVIRONMENT}\"" >> /etc/chef/client.rb
echo "ssl_verify_mode :verify_none" >> /etc/chef/client.rb

echo "Creating other needed folders/files"
sudo mkdir -p /etc/chef/ohai/hints
sudo apt-get update -y
sudo chef-client -r recipe[addressbook::app] >> /tmp/chef-first-run.log

# Patch
sudo apt-get upgrade -y
if [[ -f /var/run/reboot-required ]]; then
     sudo reboot -f
fi
