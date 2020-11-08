#!/bin/bash

# -----------------------------------------------------------------------------
# Copyright Siemens AG, 2013-2015, 2019. Part of the SW360 Portal Project.
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
# modified: michael.c.jaeger@tngtech.com
#
# -----------------------------------------------------------------------------

#
# downloading all the big downloads
#
packages='https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64-vagrant.box
https://sourceforge.net/projects/lportal/files/Liferay%20Portal/7.3.3%20GA4/liferay-ce-portal-tomcat-7.3.3-ga4-20200701015330959.tar.gz
https://search.maven.org/remotecontent?filepath=commons-codec/commons-codec/1.12/commons-codec-1.12.jar commons-codec-1.12.jar
https://search.maven.org/remotecontent?filepath=org/apache/commons/commons-collections4/4.1/commons-collections4-4.1.jar commons-collections4-4.1.jar
https://search.maven.org/remotecontent?filepath=org/apache/commons/commons-csv/1.4/commons-csv-1.4.jar commons-csv-1.4.jar
https://search.maven.org/remotecontent?filepath=commons-io/commons-io/2.6/commons-io-2.6.jar commons-io-2.6.jar
https://search.maven.org/remotecontent?filepath=commons-lang/commons-lang/2.4/commons-lang-2.4.jar commons-lang-2.4.jar
https://search.maven.org/remotecontent?filepath=commons-logging/commons-logging/1.2/commons-logging-1.2.jar commons-logging-1.2.jar
https://search.maven.org/remotecontent?filepath=com/google/code/gson/gson/2.8.5/gson-2.8.5.jar gson-2.8.5.jar
https://search.maven.org/remotecontent?filepath=com/google/guava/guava/21.0/guava-21.0.jar guava-21.0.jar
https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-annotations/2.9.8/jackson-annotations-2.9.8.jar jackson-annotations-2.9.8.jar
https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-core/2.9.8/jackson-core-2.9.8.jar jackson-core-2.9.8.jar
https://search.maven.org/remotecontent?filepath=com/fasterxml/jackson/core/jackson-databind/2.9.8/jackson-databind-2.9.8.jar jackson-databind-2.9.8.jar
https://jdbc.postgresql.org/download/postgresql-42.2.9.jar postgresql-42.2.9.jar
https://repo1.maven.org/maven2/org/apache/thrift/libthrift/0.13.0/libthrift-0.13.0.jar
https://dist.apache.org/repos/dist/release/thrift/0.13.0/thrift-0.13.0.tar.gz
https://github.com/rnewson/couchdb-lucene/archive/v2.1.0.tar.gz ./couchdb-lucene.tar.gz
https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

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
    if [ -e  xenial-server-cloudimg-amd64-vagrant.box ]; then
        echo "remove old  xenial-server-cloudimg-amd64-vagrant.box (downloaded by old version of this script)"
        rm  xenial-server-cloudimg-amd64-vagrant.box
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
        vagrant box add --force bionic-server-cloudimg-amd64-vagrant "bionic-server-cloudimg-amd64-vagrant.box"
        vagrant box add --force aws-dummy "dummy.box"
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
