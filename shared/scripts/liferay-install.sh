#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# script copying jar files from liferay-tomcat-bundle to tomcat and installng liferay into
# the tomcat/webapps/ROOT folder
# 
# -----------------------------------------------------------------------------

set -e
echo "remove ROOT directory on target tomcat"
rm -r -f /opt/apache-tomcat-7.0.67/webapps/ROOT/*

echo "deploy ROOT directory from liferay bundle .war"
/usr/bin/unzip /vagrant_shared/packages/liferay.war -d /opt/apache-tomcat-7.0.67/webapps/ROOT

echo "unpack and deploy dependencies"
mkdir /opt/apache-tomcat-7.0.67/lib/ext
/usr/bin/unzip /vagrant_shared/packages/liferay-dependencies.zip -d /tmp
cp /tmp/liferay-portal-dependencies*/*.jar /opt/apache-tomcat-7.0.67/lib/ext

echo "unpack and deploy more dependencies from liferay source code"
/usr/bin/unzip /vagrant_shared/packages/liferay-portal-src.zip -d /tmp
cp /tmp/liferay-portal-src*/lib/development/{activation,jms,jta,jutf7,mail,persistence}.jar /opt/apache-tomcat-7.0.67/lib/ext
cp /tmp/liferay-portal-src*/lib/portal/ccpp.jar /opt/apache-tomcat-7.0.67/lib/ext
mkdir -p /opt/apache-tomcat-7.0.67/temp/liferay/com/liferay/portal/deploy/dependencies
cp /tmp/liferay-portal-src*/lib/development/{resin,script-10}.jar /opt/apache-tomcat-7.0.67/temp/liferay/com/liferay/portal/deploy/dependencies

cp /vagrant_shared/packages/postgresql.jar /opt/apache-tomcat-7.0.67/lib/ext
