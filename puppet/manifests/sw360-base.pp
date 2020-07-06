#
# Copyright Siemens AG, 2013-2015,2019. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#

class sw360base {

  # Path definitions
  $java_home='/usr/lib/jvm/java-11-openjdk-amd64/'
  $tomcat_path='/opt/liferay-ce-portal-7.2.1-ga2/tomcat-9.0.17'
  $puppet_does_not_allow_escaping='deb https://apache.bintray.com/couchdb-deb bionic main'

  package { ["software-properties-common", "unzip", "curl", "git-core", "maven", "openjdk-11-jdk", "postgresql-10", "apache2", "libapache2-mod-auth-mellon"]:
    ensure  => present,
  }
  
  ##############################################################################
  # bionic does not have couchdb anymore. need to install ppa and then couchdb #                                                              #
  ##############################################################################
  
  exec { 'install-couchdb-add-repo-key':
    path => ['/usr/bin', '/usr/sbin'],
    command => "curl -L https://couchdb.apache.org/repo/bintray-pubkey.asc | sudo apt-key add -",
  }
  exec { 'install-couchdb-add-repo-url':
    path => ['/usr/bin', '/usr/sbin', '/usr/local/sbin', '/usr/local/bin', '/sbin', '/bin'],
    command => "echo $puppet_does_not_allow_escaping | sudo tee -a /etc/apt/sources.list",
    require => Exec['install-couchdb-add-repo-key'],
  }
  exec { 'install-couchdb-update-apt':
    path => ['/usr/bin', '/usr/sbin'],
    command => "sudo apt-get update -y",
    require => Exec['install-couchdb-add-repo-url'],
  }
  exec { 'install-couchdb-install-finally':
    path => ['/usr/bin', '/usr/sbin'],
    command => "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y couchdb=2.1.2~bionic",
    require => Exec['install-couchdb-update-apt'],
  }

  ##############################################################################
  # User configuration, to create the siemagrant user when starting from a     #
  # standard box.                                                              #
  ##############################################################################

  $siemagrant_group_id = 9999

  # Create siemagrant user
  user { 'siemagrant':
    ensure     => present,
    managehome => true,
    gid        => $siemagrant_group_id,
    shell      => "/bin/bash",
    password   => sha1('sw360fossy')
    # password   => '$6$B4hzJu3a$isbQ00fcV12gL03n3adLELDoPsWbLKhckgNEdnCrjtQj1g1PegHHoEyQ0ckmL7O/pnV4hErZBWFXebAoBfhTu/', # sw360fossy
  }

  group { 'siemagrant':
    gid => $siemagrant_group_id
  }

  # Setting the sudoers
  file_line { 'sudoers':
    ensure => present,
    line   => "siemagrant ALL=(ALL) NOPASSWD: ALL",
    path   => '/etc/sudoers',
  }

  #################
  # Generate keys #
  #################

  exec { 'generate-ssh-keys':
    command => "/vagrant_shared/scripts/generate-keys.sh",
    user    => root,
    path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
    require => User['siemagrant'],
  }

  ############################
  # General Box Configuation #
  ############################

  # Setting the JAVA_HOME environment variable
  file_line { 'java home':
    ensure => present,
    line   => "JAVA_HOME=${java_home}",
    path   => '/etc/environment',
  }

  #################
  ## Maven Setup ##
  #################

  # Unpack the chached maven repository to avoid downloading it each time a VM
  # is created
  # This requires, that the maven repository was already exported
  exec { 'm2repo':
    command => "/bin/tar xvzf /vagrant_shared/packages/m2repo.tar.gz -C /home/siemagrant",
    onlyif  => "test -f /vagrant_shared/packages/m2repo.tar.gz",
    path    => ['/usr/bin','/usr/sbin','/bin','/sbin'],
    user    => 'siemagrant',
    require => User['siemagrant'],
  }

  # settings.xml: Saves the login settings for maven tomcat:deploy including proxy if configured
  file { 'maven_settings.xml':
    path    => '/etc/maven/settings.xml',
    ensure  => 'present',
    content => template('sw360/maven_settings.xml.erb'),
    require => Package['maven'],
  }

  ##################
  ## Thrift Setup ##
  ##################

  exec { 'install_thrift':
    command => "/vagrant_shared/scripts/install-thrift.sh",
    user    => root,
    timeout => 1800,
    creates => "/usr/local/bin/thrift",
  }

  ###################
  ## Liferay Setup ##
  ###################
  
  # execute beasic unpack and copy of liferay distro
  exec { 'liferay-install':
    command => "/vagrant_shared/scripts/liferay-install.sh",
    user    => 'siemagrant',
    require => [Package['unzip']],
  }
  
  ###################
  ## Lucene Setup  ##
  ###################

  exec { 'install_lucene':
    command => "/vagrant_shared/scripts/install-lucene.sh",
    user    => 'root',
    timeout => 1800,
    require => [Package['unzip','maven','openjdk-11-jdk'], File['maven_settings.xml'], Exec['liferay-install']],
    creates => "${tomcat_path}/webapps/couchdb-lucene.war",
  }

  ###################
  ## Apache Setup ##
  ###################

  exec { 'enable-apache-mod-ssl':
    command => "/usr/sbin/a2enmod ssl",
    user    => root,
    require => [Package['apache2']],
  }

  exec { 'enable-apache-mod-proxy_http':
    command => "/usr/sbin/a2enmod proxy_http",
    user    => root,
    require => [Package['apache2']],
  }

  exec { 'enable-apache-mod-headers':
    command => "/usr/sbin/a2enmod headers",
    user    => root,
    require => [Package['apache2']],
  }

  if $enable_mellon {
    exec { 'enable-apache-mod-auth-mellon':
      command => "/usr/sbin/a2enmod auth_mellon",
      user    => root,
      require => [Package['apache2', 'libapache2-mod-auth-mellon']],
    }
  }
}

include sw360base
