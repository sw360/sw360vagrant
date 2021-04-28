#
# Copyright Siemens AG, 2013-2016. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# This file will be parsed as Ruby __and__ Bash for configuration puroses. This
# means that it has to be syntactically valid for both

# Set this to "true" if you want vagrant to install sw360 automatically
SW360_install=true

# Set this to "true" when working with a network behind a proxy
SW360_proxy=false
SW360_proxy_http="http://192.168.1.1:3128"
SW360_proxy_https="http://192.168.1.1:3128"
SW360_proxy_bypass="localhost,127.0.0.1"

# if you need an additional "host only" network for accessing the host via network
# e.g. for a local proxy server on the host
# than switch the following option to true
SW360_network_host=false

SW360_default_password="sw360fossy" # admin password for liferay and tomcat
SW360_admin_name="setup" # admin account name for liferay (only!)

SW360_vm_name="sw360-focal-installed" # how the vm is named in your hypervisor
SW360_basebox_name="sw360-focal" # which base box vagrant should consider
SW360_vagrant_user="siemagrant" # the user created and used for the installation process
SW360_enable_mellon=false # set to true to prepare for SAML authentication by installing and enabling mod_auth_mellon
SW360_use_insecure_Keypair=true # setting this to true forces Vagrant to use the keypair in shared/insecureKeypair

SW360_https_port=8443 # https port
SW360_couchDB_port=5984 # set to "" to stop forwarding couchdb
SW360_tomcat_debug_port=5005 # set to "" to deactivate tomcat debugging
SW360_max_upload_filesize="1000m" # set the max upload files size in apache in MB

# Setting the following variable will overwrite all git settings
# For good performance this requires a Vagrant of version >= 1.5
# For synchronization you might have to start `vagrant rsync-auto` manually
SW360_source=""
SW360_gitURL="https://github.com/eclipse/sw360.git"
SW360_branch="" # the value "" means: "don't change the branch"
SW360_fossology_address="172.16.101.143" # FOSSology configuration:

# Vagrant provider system
SW360_provider="virtualbox" # available providers for vagrant: virtualbox, aws

# Virtualbox section
# Please refer to SW360_provider and set the value to virtualbox
SW360_VB_CPUs=4 # well, how many logical cores ...
SW360_VB_RAM=12000 # RAM in MB, should be at least 5GB
SW360_VB_DISK="20GB" # disk space in GB, should be at least 12GB

# AWS section
# Please refer to SW360_provider and set the value to aws
# Set your AWS environment variables 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY'
SW360_AWS_keypair_name="" # specify the key pair name in your AWS account # e.g. vagrant-aws-key
SW360_AWS_region="" # e.g. eu-central-1
SW360_AWS_availability_zone="" # e.g. eu-central-1a
SW360_AWS_subnet_id="" # e.g. subnet-23b9e7h1
SW360_AWS_ami_base="" # Ubuntu Xenial AMI (depends on region and available AMI's) e.g. ami-7c412f13
SW360_AWS_ami_single="" # generated basebox AMI (output of generate_box.sh) e.g. ami-b294cc59
SW360_AWS_security_groups=['default'] # e.g. 'default', sg-945eeaf9
SW360_AWS_ssh_user="" # e. g. ubuntu
SW360_AWS_ssh_private_key="" # specify the path of the private key pem file
# AWS specific machine settings
SW360_AWS_instance_type="" # e.g. m4.large
SW360_AWS_device_mapping_name="" # e.g. /dev/sdl
SW360_AWS_device_mapping_virtual_name="" # e.g. sw360 device
SW360_AWS_device_mapping_ebs_size=100 # e. g. 100
SW360_AWS_device_mapping_type="" # e.g. gp2 (SSD) or magnetic (HDD) storage
