#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2013-2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# downloading script for getting external packages
# in the Vagrant machine of the SW360 project
# and having to download them only once.
#
# initial author: cedric.bodet@tngtech.com
# modified: birgit.heydenreich@tngtech.com
# modified: maximilian.huber@tngtech.com
# -----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# NB: Upgrading to tomcat 8 will be possible as soon as the following issue is
# fixed:
# https://issues.liferay.com/browse/LPS-61760
# 
# Then use e.g.: http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.28/bin/apache-tomcat-8.0.28.tar.gz apache-tomcat.tar.gz
#------------------------------------------------------------------------------

#download liferay.war for deployment within tomcat and both liferay dependencies and liferay source code in order to get the necessary jar-files 
packages='http://cloud-images.ubuntu.com/vagrant/trusty/current/trusty-server-cloudimg-amd64-vagrant-disk1.box
http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.67/bin/apache-tomcat-7.0.67.tar.gz apache-tomcat.tar.gz
http://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.4%20GA5/liferay-portal-6.2-ce-ga5-20151118111117117.war liferay.war
http://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.4%20GA5/liferay-portal-dependencies-6.2-ce-ga5-20151118111117117.zip liferay-dependencies.zip
http://downloads.sourceforge.net/project/lportal/Liferay%20Portal/6.2.4%20GA5/liferay-portal-src-6.2-ce-ga5-20151118111117117.zip liferay-portal-src.zip
https://github.com/rnewson/couchdb-lucene/archive/v1.0.2.tar.gz ./couchdb-lucene.tar.gz
https://jdbc.postgresql.org/download/postgresql-9.4.1207.jar postgresql.jar
https://dist.apache.org/repos/dist/release/thrift/0.9.3/thrift-0.9.3.tar.gz'

# -----------------------------------------------------------------------------
#   Functions
# -----------------------------------------------------------------------------
have() { type "$1" &> /dev/null; }
have wget || {
    echo "In order to run this script one needs to have wget installed"
    exit 1
}
downloadAll(){
    download(){
        if [ "$#" -eq 1 ]; then
            echo "-[] Download `basename $1`"
            wget --timestamping $1
            return
        fi
        if [ -e $2 ]; then
            onlineSize=`wget $1 --spider --server-response -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`
            localSize=`wc -c < $2`
            if [ "$onlineSize" = "$localSize" ]; then
                echo "-[] The file $1 has the same size as the online version. No download."
                return
            fi
        fi
        echo "-[] Download $2"
        wget -O $2 $1
    }

    echo "-[] Downloading external packages to be used by the Vagrant provisioning."
    echo "$packages" | while read packageWithDest; do
        download $packageWithDest
    done
    echo "-[] All external packages downloaded"
}
getTargetName() {
    if [ "$#" -eq 1 ]; then
        echo `basename $1`
    elif [ "$#" -eq 2 ]; then
        echo $2
    fi
}
cleanAll(){
    echo "$packages" | while read packageWithDest; do
        rm `getTargetName $packageWithDest`
    done
    if [ -e apache-tomcat-8.0.26.tar.gz ]; then
        echo "remove old apache-tomcat-8.0.26.tar.gz (downloaded by old version of this script)"
        rm apache-tomcat-8.0.26.tar.gz
    fi
    echo "remove old liferay-tomcat-bundle versions" 
    rm liferay-portal-tomcat-6.2-ce-ga*.zip 2>/dev/null  
}
areAllFilesHere(){
    echo "$packages" | while read packageWithDest; do
        if [ ! -e `getTargetName $packageWithDest` ]; then exit 1; fi
    done || exit 1
    exit 0
}
setPermissions(){
    pushd $1 &>/dev/null
    echo "-[] Set read / execute permissions for other users"
    find . -exec chmod o+r {} \;
    find . -type d -exec chmod o+x {} \;
    find . -type f -name '*.sh' -exec chmod o+x {} \;
    popd &>/dev/null
}
addBoxToVagrant(){
        vagrant box add --force trusty-server-cloudimg-amd64-vagrant-disk1 "trusty-server-cloudimg-amd64-vagrant-disk1.box"
}

# -----------------------------------------------------------------------------
#   Run
# -----------------------------------------------------------------------------
DIR=$(realpath "$( dirname $0 )/shared/packages")
mkdir -p "$DIR" && pushd "$DIR" &>/dev/null
case $1 in
    --clean)
        cleanAll
        ;;
    --check)
        areAllFilesHere
        ;;
    *)
        downloadAll
        addBoxToVagrant
        setPermissions $(dirname $DIR)
    ;;
esac
popd &>/dev/null
