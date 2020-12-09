#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2013-2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# -----------------------------------------------------------------------------

set -eo pipefail

have() { type "$1" &> /dev/null; }
have vagrant || {
    echo "In order to run this script one needs to have vagrant installed"
    exit 1
}

configurationFile="$(dirname $0)/../shared/configuration.rb"
source $configurationFile

pushd `dirname $0` >/dev/null

../download-packages.sh --check || {
    echo "Not all necessary packages are found in '../shared/packages/'."
    echo "In order to run this script, you first have to run '../download-packages.sh'."
    exit 1
}

if [ -f "${SW360_basebox_name}.box" ]; then
   echo "Moving previously created ${SW360_basebox_name}.box found, moving to ${SW360_basebox_name}.box_old."
   mv "${SW360_basebox_name}.box" "${SW360_basebox_name}.box_old"
else
   echo "No previously created folder found, moving on."
fi

echo "-[] Destroy old box (if created previously and script exited with failure)"
vagrant destroy -f

echo "-[] Create and provision new box"
vagrant up

echo "-[] Package the box"
vagrant package --output "${SW360_basebox_name}.box"

echo "-[] Add the box to the list of known boxes"
vagrant box add --force "$SW360_basebox_name" "${SW360_basebox_name}.box"

echo "-[] Destroy the generated box"
vagrant destroy -f

popd
