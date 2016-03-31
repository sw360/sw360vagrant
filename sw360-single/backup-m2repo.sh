#!/bin/sh

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2013-2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Making a backup of the ~/.m2/ folder to avoid redownloading all artifacts
# each time a new box is created
#
# initial author: cedric.bodet@tngtech.com
# 
# -----------------------------------------------------------------------------

echo "Making a backup of the ~/.m2/ folder"

tar zcf /vagrant_shared/packages/m2repo.tar.gz -C ~/ .m2 

echo "Your ~/.m2/ folder is saved under /vagrant_shared/packages/m2repo.tar.gz"
