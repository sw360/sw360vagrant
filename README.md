### 0. Overview

Bascially, the vagrant install is about the following:

* Install virtualbox and vagrant
* run ```./download-packages.sh```
* run ```./generate-box/generate_box.sh```
* cd into sw360-single/ and execute ```vagrant up```

The main reason why downloading pakages and creating the base box is separate
from vagrant provisioning is that downloading and provisioning of dependencies
takes some time. And this not necessary every time a deployment is started.

Please see details about this below. Tested with linux, windows and macosx. The hardware requirements can bee seen in the `shred/configuration.rb` file.

### 1. Prerequisites

The following packages are needed to install the SW360 software in a vagrant box:

```
* virtualbox
* vagrant
```

Clone from this repository.

if you need to use a proxy server please follow this additional instructions before starting with the next chapter:

* install the AWS plugin for vagrant if you setup AWS as provider
```
$ vagrant plugin install vagrant-aws
```
(although you will not deploy to AWS, it is required, because vagrant parses the description files and finds some conditional statements which are not ignored)
* install the disk size plugin for vagrant to change the virtual disk size (new!)
```
$ vagrant plugin install vagrant-disksize
```
* Check if some proxy config is made on the host system
```
$ env | grep proxy
```
* Install the proxy plugin for vagrant which does a lot of work for you (enviroment, apt.conf, ..)
```
$ vagrant plugin install vagrant-proxyconf
```
* adapt the Vagrantfile in the generate-box folder to set the proxy information
```
$ vi shared/configuration.rb
```
```
# Set this to "true" when working with a network behind a proxy
SW360_proxy=true
SW360_proxy_http="http://192.168.1.1:3128"
SW360_proxy_https="https://192.168.1.1:9443"
SW360_proxy_bypass="localhost,127.0.0.1"
```
* If you need proxy authentication on your proxy server, you could consider installing a local proxy server (like cntlm) because maven is not supporting proxy authentication. In this case you only have to enable SW360_proxy=true and enable SW360_network_host=true and leave the rest as it is. Otherwise you can directly configure your proxy here.

### 2. Download dependencies

In order to avoid excessive Internet downloads, it is required to download some packages
before starting to build boxes. That way, those files are not re-downloaded each time a
new box is created. To start the downloads, run the following script:

```
$ ./download-packages.sh
```

(wget is used, might not work under Windows, but the files can also be downloaded
manually)

The packages that are downloaded to `./shared/packages` are:
* Liferay 7.3.3 CE GA4 with Tomcat (9.0.33)
* Postgresql ODBC client for Java as *.jar file
* Eleven *.jar files which are required for SW360 as dependencies, downloaded separately because of the OSGi-dependency mechanism of the Liferay
* A box image from the Ubuntu 18.04 LTS server, namely `bionic-server-cloudimg-amd64-vagrant.box`. Note that the latter is constantly updated and thus it make sense to download a new base box from time to time if you do not manually update packages inside.
* Couchdb-Lucene 2.1 which needs to be patched because we need a separate URL trailing path (`/couchdb-lucene`) to have it running in the same tomcat as the portal itself (which should be reachable without a trailing path).
* Apache Thrift 0.13

The main dependencies are installed as packages in side the base box build (see below):

* OpenJDK 11
* CouchDB 2.1.2 (actually, also other versions of CouchDB might work as well)

### 3. Generate base box

In short, to generate the base box, simply do:

```
$ cd generate-box
$ ./generate_box.sh
```

This can take a while, but the the sw360-base box will be created, installed and ready to use.

In a bit longer, the `generate_box.sh` script creates a new box based on a standard Ubuntu 18.04 box as downloaded before. Puppet then installs the required aptitude packages (openjdk-11-jdk, curl, unzip, couchdb, maven, gitcore, postgresql, apache), generates the couchdb-lucene.war, unpacks tomcat and liferay, creates a new user "siemagrant" and adds a ssh key to it, so that the box can be accessed by ssh logging without password.

### 4. Provision a new box

If you have built a vagrant box from this directory earlier, you will have to destroy it first via

```
$ vagrant destroy
```

It is recommended to use vagrant version 1.5 or higher, since in this case synchronisation of your local source directory on your host machine with the vagrant box will be al lot faster. In this case, simply execute:

```
$ cd sw360-single
$ SW360_SOURCE=/path/to/sourcedir/ vagrant up && vagrant rsync-auto
```
In case you want the source code to be taken from the master branch of https://github.com/eclipse/sw360, you simply need to run

```
$ cd sw360-single
$ vagrant up
```

The provisioning of the box (via puppet) configures liferay, postgresql and couchdb for the purpose of SW360 (port, paths, admin passwords, ...).

Additionally, apache is configured to terminate TLS on port 8443 with a newly created self signed certificate.

If the option `sw360_install=true (default)` is used in the Vagrantfile, then also the code is fetched from Github, compiled with maven and deployed using a `mvn deploy` command

In principle, another base box can be used, as long as the required packages are installed
(see above) and if the Vagrantfile is modified to contain the correct log-in information
for the siemagrant user.

### 5. Installing and deploying SW360

This step is only necessary if the previous step was run with the option `sw360_install=false` in the Vagrantfile. The goal is to build and deploy SW360 in the Vagrantbox. To do so, ssh to the newly created
box and run the `sw360-install.sh` script.

```
$ vagrant ssh
$ ./sw360-install.sh
```
You can configure the installation using various options. See `./sw360-install.sh -h` to get an overview.

### 6. (optional) Generating the Maven repository

If you have just created the vagrant box, you should generate a maven repository with all the maven files that were just downloaded. This saves time when building boxes multiple times. Via the ssh-connection to your box, run:

```
$ cd /vagrant
$ ./backup-m2repo.sh
```
A maven repository with all necessary maven files is created from `~/.m2` on the vagrantbox. After destroying the vagrant box via

```
$ exit # exit the ssh connection
$ vagrant destroy,
```
run steps 2, 3 and 4 again in order to install the maven repository to the box. This makes building the sw360 project a lot quicker in the future. After that, proceed with step 6.

### 7. (not optional) Deploying the SW360 layout to Liferay

The last mandatory step  is to manually setup liferay and also deploy the site layout into Liferay (as sadly automatic
deployment is not working). To that end, log in to the Liferay instance (what ever was defined in the confguration.rb) as user `setup@sw360.org`, the default password is `sw360fossy` but it can be modified in the  configuration (`shared/configuration.rb`). Check whether the SW360 is present in Liferay.

In order to further setup liferay, follow the wiki pages of this project or [the public repository] (https://github.com/eclipse/sw360/wiki/)

Your SW360 is now ready!

### 8. Changing the external port

If you want to change the port on which sw360 is accessible from its default 8443 to something else, this needs to be changed in two locations.
  * obviously the Vagrant file: `config.vm.network "forwarded_port", guest: 8443, host: <your_port_here>`
  * and the liferay configuration in `puppet/modules/sw360/templates` since it generates absolute links: `web.server.https.port=<your_port_here>`

### 9. Problems

Note: no proxy support for vagrant provider AWS.
Please run the setup in a non proxy environment.

### 10. License

Copyright Siemens AG, 2013-2016,2018,2019,2020. Part of the SW360 Portal Project.

For files created as vagrant scripts for the sw360portal project, the following license applies:

Copying and distribution of the vagrant files, templates and scripts for sw360, with or without modification, are permitted in any medium without royalty provided the copyright notice and this notice are preserved. For included third party software, please refer to the README_OSS.md. This file is offered as-is, without any warranty.
