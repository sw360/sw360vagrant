#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2015,2020. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# script copying the download, unpacking this
#
# -----------------------------------------------------------------------------

set -e
echo "-[shell provisioning] Start installing liferay ..."

sudo cp /vagrant_shared/packages/liferay-ce-portal-tomcat-7.3.4-ga5-20200811154319029.tar.gz /opt
cd /opt
sudo tar -xvf liferay-ce-portal-tomcat-7.3.4-ga5-20200811154319029.tar.gz
sudo chown -R siemagrant:siemagrant liferay-ce-portal-7.3.4-ga5
sudo rm -f liferay-ce-portal-tomcat-7.3.4-ga5-20200811154319029.tar.gz

#
# postgresql jdbc driver needs to be covered as well ...
#
cp /vagrant_shared/packages/postgresql-42.2.9.jar /opt/liferay-ce-portal-7.3.4-ga5/tomcat-9.0.33/lib/ext

echo "-[shell provisioning] end of installing liferay."
