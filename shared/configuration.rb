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
SW360_proxy_https="https://192.168.1.1:9443"
SW360_proxy_bypass="localhost,127.0.0.1"

# if you need an additional "host only" network for accessing the host via network
# e.g. for a local proxy server on the host
# than switch the following option to true
SW360_network_host=false

SW360_default_password="sw360fossy" # admin password for liferay and tomcat
SW360_admin_name="setup" # admin account name for liferay (only!)

SW360_vm_name="sw360-single" # how the vm is named in your hypervisor
SW360_basebox_name="sw360-trusty" # which baso box vagrant should consider
SW360_vagrant_user="siemagrant" # the user created and used for the installation process

SW360_use_insecure_Keypair=false # setting this to true forces Vagrant to use the keypair in shared/insecureKeypair

SW360_CPUs=4
SW360_RAM=8192

SW360_https_port=8443
SW360_couchDB_port=5984 # set to "" to stop forwarding couchdb
SW360_tomcat_debug_port=5005 # set to "" to deactivate tomcat debugging
SW360_max_upload_filesize="1000m" # set the max upload files size in nginx in MB

# Setting the following variable will overwrite all git settings
# For good performance this requires a Vagrant of version >= 1.5   
# For synchronization you might have to start `vagrant rsync-auto` manually
SW360_source=""

SW360_gitURL="https://github.com/sw360/sw360portal.git"
SW360_branch="" # the value "" means: "don't change the branch"

# FOSSology configuration:
SW360_fossology_address="172.16.101.143"
