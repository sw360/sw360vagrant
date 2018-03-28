### 0. Overview

Bascially, the vagrant install is about the following:

* Install virtualbox and vagrant
* run ```./download-packages.sh```
* run ```./generate-box/generate_box.sh```
* cd into sw360-single/ and execute ```vagrant up```

The main reason why downloading pakages and creating the base box is separate
from vagrant provisioning is that downloading and provisioning of dependencies
takes some time. And this not necessary every time a deployment is started.

Please see details about this below. Tested with linux, windows and macosx.

### 1. Prerequisites

The following packages are needed to install the SW360 software in a vagrant box:

```
* vagrant
* virtualbox
``` 

Clone from this repository.

if you need to use a proxy server please follow this additional instructions before starting with the next chapter:

* Make sure that the proxy config is made on the host system
```
$ env | grep proxy
```
* install the proxy plugin for vagrant which does a lot of work for you (enviroment, apt.conf, ..)
```
$ vagrant plugin install vagrant-proxyconf
```
* install the AWS plugin for vagrant if you setup AWS as provider
```
$ vagrant plugin install vagrant-aws
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
* if you need proxy authentication on your proxy server please use a local proxy server (like cntlm) because maven is not supporting proxy authentication. In this case you only have to enable SW360_proxy=true and enable SW360_network_host=true and leave the rest as it is. Otherwise you can directly configure your proxy here.

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
* The Ubuntu cloud-image box xenial-server-cloudimg-amd64-vagrant.box
* Apache Tomcat 7.0.67
* Liferay 6.2.3-GA5
* Couchdb-lucene 4.2.10
* Postgresql-42.2.1

### 3. Generate base box


In short, to generate the base box, simply do:

```
$ cd generate-box
$ ./generate_box.sh
```

This can take a while, but the the sw360-base box will be created, installed and ready
to use.

In a bit longer, the `generate_box.sh` script creates a new box based on a standard Ubuntu 16.04 box. Puppet then installs the required aptitude packages (openjdk-8-jdk, curl, unzip, couchdb, maven, gitcore, postgresql, apache), generates the couchdblucene.war, unpacks tomcat and liferay, creates a new user "siemagrant" and adds a ssh key to it, so that the box can be accessed by ssh logging without password.

### 4. Provision a new box


With this step, a new box is created from the sw360-base box and is configured to allow
for the deployment of SW360. Before that, the fossology keys 


* fossology.id_rsa and
* fossology.id_rsa.pub


have to be copied into the `./shared` directory. Furthermore, the `/shared/fossology.properties` might have to be adjusted.

If you have built a vagrant box from this directory earlier, you will have to destroy it first via

```
$ vagrant destroy
```

It is recommended to use vagrant version 1.5 or higher, since in this case synchronization of your local source directory on your host machine with the vagrant box will be al lot faster.
In this case, simply execute:

```
$ cd sw360-single
$ SW360_SOURCE=/path/to/sourcedir/ vagrant up && vagrant rsync-auto
```
In case you want the source code to be taken from the master branch of https://github.com/siemens/sw360portal.git, you simply need to run

```
$ cd sw360-single
$ vagrant up
```
The provisioning of the box (via puppet) configures liferay, tomcat8, and couchdb for the purpose of SW360 (port, paths, admin passwords, ...). 
Additionally, apache is configured to terminate TLS on port 8443 with a newly created self signed certificate.
If the option `sw360_install=true (default)` is used in the Vagrantfile, then also the code is fetched from Github, compiled with maven and deployed using tomcat:deploy (backend) and mvn install -Pdeploy (frontend) respectively. The fossology keys are copied to the appropriate directories. The tomcat instance for the backend
and the liferay instance for the frontend start.

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

If you have just created the vagrant box, you should generate a maven repository with all the maven files that were just downloaded. Via the ssh-connection to your box, run:

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

### 7. Deploying the SW360 layout to Liferay


The last step is to manually deploy the site layout into Liferay (as sadly automatic
deployment is not working). To that end, log in to the Liferay instance (127.0.0.1:8081) as user setup@sw360.org,
the default password is "sw360fossy" but it can be modified in the Puppet configuration (sw360-single.pp). Check
whether the SW360 is present in Liferay. If it is not, restart the Liferay instance. 

```
$ /opt/liferay-portal-6.2*/tomcat-7*/bin/shutdown.sh 
$ /opt/liferay-portal-6.2*/tomcat-7*/bin/startup.sh 
```
In order to further setup liferay, follow [the public repository] (https://github.com/siemens/sw360portal/wiki/Setup-Liferay)

Your SW360 is now ready!

### 8. Changing the external port

If you want to change the port on which sw360 is accessible from its default 8443 to something else, this needs to be changed in two locations.
  * obviously the Vagrant file: `config.vm.network "forwarded_port", guest: 8443, host: <your_port_here>`
  * and the liferay configuration in `puppet/modules/sw360/templates` since it generates absolute links: `web.server.https.port=<your_port_here>`

### 9. Problems

Note: no proxy support for vagrant provider AWS.
Please run the setup in a non proxy environment.

### 10. License

Copyright Siemens AG, 2013-2016. Part of the SW360 Portal Project.

For files created as vagrant scripts for the sw360portal project, the following license applies:

Copying and distribution of the vagrant files, templates and scripts, with or without modification,
are permitted in any medium without royalty provided the copyright
notice and this notice are preserved.  This file is offered as-is,
without any warranty.

For files imported to the project, see the README_OSS file.
