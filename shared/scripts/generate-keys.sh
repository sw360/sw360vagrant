#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# script automatically generating keys for password-free login onto
# the vagrantbox
#
# initial author: birgit.heydenreich@tngtech.com
# 
# -----------------------------------------------------------------------------

set -e

configurationFile="/vagrant_shared/configuration.rb"
source $configurationFile

echo "-[shell provisioning] Setting up Keys"

#generate private_key_vagrant and public_key_vagrant
if [ "$SW360_use_insecure_Keypair" = true ]; then
  privateKey="/vagrant_shared/insecureKeypair/siemagrant"
else
  echo "-[shell provisioning] Generating keys"
  ssh-keygen -t rsa -f "/tmp/tmpkey" -q -N "" -C "This key was generated for SW360"
  privateKey="/tmp/tmpkey"

  privateKeyTarget="/vagrant_shared/siemagrant_key_for_${SW360_basebox_name}"
  if [ -f $privateKeyTarget ]; then
    echo "private key vagrant already exists"
    mv "$privateKeyTarget" "${privateKeyTarget}_old}"
  fi
  cp "$privateKey" "$privateKeyTarget"
fi
publicKey="$privateKey.pub"

mkdir -p /home/siemagrant/.ssh
cat "$publicKey" > /home/siemagrant/.ssh/authorized_keys
chown -R siemagrant:siemagrant /home/siemagrant/.ssh/
chmod 700 /home/siemagrant/.ssh/
chmod 600 /home/siemagrant/.ssh/authorized_keys

if [ ! "$SW360_use_insecure_Keypair" = true ]; then
  rm "$privateKey" "$publicKey"
fi
