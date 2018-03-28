#
# Copyright Siemens AG, 2013-2015. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#

class box-configuration {

  # Path definitions
  $java_home='/usr/lib/jvm/java-8-openjdk-amd64/jre/'
  $tomcat_path='/opt/apache-tomcat-7.0.67'
  $liferay_data_path=['/opt/liferay','/opt/liferay/data']
  $tomcatconf_path=['/opt/apache-tomcat-7.0.67/conf','/opt/apache-tomcat-7.0.67/conf/Catalina','/opt/apache-tomcat-7.0.67/conf/Catalina/localhost']

  class { 'apt':
    always_apt_update => true;
  }

  apt::ppa { 'ppa:openjdk-r/ppa':
    before => [Exec['install-openjdk']]
  }

  package { ["unzip", "curl", "git-core", "maven", "openjdk-8-jdk", "couchdb", "postgresql-9.5", "apache2",
    "libapache2-mod-auth-mellon"]:
    ensure  => present,
    require => Class['apt'],
  }

  exec { 'install-openjdk':
    command => "/usr/bin/apt-get -q -y --force-yes -o DPkg::Options::=--force-confold install openjdk-8-jdk",
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

  # Add LIFERAY_PATH environment variable
  file_line { 'liferay path':
    ensure => present,
    line   => "LIFERAY_PATH=${tomcat_path}",
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
  ## Tomcat7 Setup ##
  ###################

  # Tomcat7 directory
  file { $tomcat_path:
    ensure  => 'directory',
    owner   => 'siemagrant',
    require => User['siemagrant'],
  }

  # Unpack Tomcat7
  exec { 'unpack_tomcat7':
    command => "/bin/tar xvzf /vagrant_shared/packages/apache-tomcat.tar.gz -C /opt",
    user    => 'siemagrant',
    require => [User['siemagrant'],File[$tomcat_path]],
    creates => "${tomcat_path}/LICENSE",
  }

#------------------------------------------------------------
# NB: the following will only
# be necessary when tomcat 8 is used
#------------------------------------------------------------
# Disable tomcat caching to avoid excessive log output
#  file { 'context.xml':
#    path    => "${tomcat_path}/conf/context.xml",
#    content => template('sw360/context.xml'),
#    owner   => 'siemagrant',
#    ensure  => present,
#    require => [File[$tomcatconf_path],Exec['unpack_tomcat7','liferay-install']],
#  }

  ###################
  ## Lucene Setup  ##
  ###################

  exec { 'install_lucene':
    command => "/vagrant_shared/scripts/install-lucene.sh",
    user    => 'root',
    timeout => 1800,
    require => [Package['unzip','maven','openjdk-8-jdk'], Exec['unpack_tomcat7'], File['maven_settings.xml']],
    creates => "/opt/apache-tomcat-7.0.67/webapps/couchdb-lucene.war",
  }

  ###################
  ## Liferay Setup ##
  ###################

  #Create Liferay directory
  file { $liferay_data_path:
    ensure  => 'directory',
    owner   => 'siemagrant',
    require => User['siemagrant'],
  }

  # Remove the default database, which defines default pages and user but also
  # overrides the configuration of the server in "portal-ext.properties"
  file { 'lportal.properties':
    path    => "${liferay_data_path}/hsql/lportal.properties",
    ensure  => absent,
    require => File[$liferay_data_path],
  }

  file { 'lportal.script':
    path    => "${liferay_data_path}/hsql/lportal.script",
    ensure  => absent,
    require => File[$liferay_data_path],
  }

  # Ensure tomcat config path
  file { $tomcatconf_path:
    ensure  => 'directory',
    owner   => 'siemagrant',
    require => User['siemagrant'],
  }

  # Configuration ROOT.xml that allows multiple web apps to use
  file { 'ROOT.xml':
    path    => "${tomcat_path}/conf/Catalina/localhost/ROOT.xml",
    content => template('sw360/ROOT.xml'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File[$tomcatconf_path],
  }

  # Configuration to make ext libs available for liferay
  file { 'catalina.properties':
    path    => "${tomcat_path}/conf/catalina.properties",
    content => template('sw360/catalina.properties'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File[$tomcatconf_path],
  }

  # Correct liferay's web.xml to avoid security warnings
  file { 'web.xml':
    path    => "${tomcat_path}/webapps/ROOT/WEB-INF/web.xml",
    content => template('sw360/web.xml'),
    owner   => 'siemagrant',
    ensure  => present,
    require => [Exec['unpack_tomcat7','liferay-install']],
  }

  exec { 'liferay-install':
    command => "/vagrant_shared/scripts/liferay-install.sh",
    user    => 'siemagrant',
    creates => "/opt/apache-tomcat-7.0.67/lib/ext/activation.jar",
    require => [Exec['unpack_tomcat7'],File['ROOT.xml'],Package['unzip']],
  }

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

include box-configuration
