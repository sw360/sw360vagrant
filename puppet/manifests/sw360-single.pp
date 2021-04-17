#
# Copyright Siemens AG, 2013-2015,2019,2020. Part of the SW360 Portal Project.
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#

class sw360single {

  $tomcat_port           = '8080' #Default: 8080
  $tomcat_server_port    = '8025' #Default: 8005
  $tomcat_ajp_port       = '8029' #Default: 8009

  # Bind to 0.0.0.0 to allow access outside the VM, and to 127.0.0.1 to prevent it
  $couchdb_bind_address = '0.0.0.0'
  $couchdb_bind_port    = '5984'

  # Path definitions
  $tomcat_path='/opt/liferay-ce-portal-7.3.4-ga5/tomcat-9.0.33'
  $liferay_install='/opt/liferay-ce-portal-7.3.4-ga5'
  $sw360_settings_path='/etc/sw360'

  ############################
  # General Box Configuation #
  ############################

  # Ensure that the standard Vagrant user is not there anymore
  # This prevents logging in with the usual vagrant/vagrant credentials.
  user { 'vagrant':
    ensure     => absent,
  }

  # Link the SW360 installation script to the home folder (for convenience)
  file { '/home/siemagrant/sw360-install.sh':
    ensure => 'link',
    owner  => 'siemagrant',
    target => '/vagrant/sw360-install.sh',
  }

  # adding virtual box shared folder
  file { '/sw360portal':
    ensure => 'directory',
    owner  => 'siemagrant',
  }

  # todo put this into the generate-box build
  file_line { "liferay_install":
    ensure  => present,
    line    => "LIFERAY_INSTALL=$liferay_install",
    path    => "/etc/environment",
  }

  ###################
  ## CouchDB Setup ##
  ###################

  # local.ini: Setup of CouchDB bind port and bind adress
  file { 'couchdb_local.ini':
    path    => '/opt/couchdb/etc/local.ini',
    ensure  => 'present',
    owner   => couchdb,
    content => template('sw360/couchdb_local.ini.erb'),
    notify  => Service["couchdb"], # Will cause the service to restart
  }

  # Restart CouchDB
  service { 'couchdb':
    ensure  => "running",
    enable  => "true",
    require => File['couchdb_local.ini'],
  }

  ####################
  ## Postgres Setup ##
  ####################

  class { 'postgresql::server': }

  postgresql::server::db { 'lportal':
    user     => 'liferay',
    password => postgresql_password('liferay', $liferay_admin_password),
  }

  ##################
  ## Tomcat Setup ##
  ##################

  # Adding administrator to Tomcat and setting its password
  file { 'tomcat-users.xml':
    path    => "${tomcat_path}/conf/tomcat-users.xml",
    content => template('sw360/tomcat_tomcat-users.xml.erb'),
    ensure  => present,
  }

  # Setting the ports on which the backend will run, and setting dependencies
  file { 'server.xml':
    path    => "${tomcat_path}/conf/server.xml",
    content => template('sw360/tomcat_server.xml.erb'),
    ensure  => present,
  }

  ###################
  ## Liferay Setup ##
  ###################

  # Configuration of the server (default admin name/password, portal settings, ...)
  file { 'portal-developer.properties':
    path    => "${tomcat_path}/webapps/ROOT/WEB-INF/classes/portal-developer.properties",
    content => template('sw360/liferay_portal-developer.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
  }

  # Configuration of the server (default admin name/password, portal settings, ...)
  file { 'portal-ext.properties':
    path    => "${liferay_install}/portal-ext.properties",
    content => template('sw360/liferay_portal-ext.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
  }

  #################
  ## SW360 Setup ##
  #################

  # install basic dependencies
  exec { 'liferay-install-bundle-deps':
    command => "/vagrant_shared/scripts/install-bundle-deps.sh",
    user    => 'siemagrant',
  }

  #  creation of sw360 settings dir
  file { 'sw360-dir':
    path    => "${sw360_settings_path}",
    owner   => 'siemagrant',
    group  => 'siemagrant',
    ensure => 'directory',
  }

  # Configuration of the sw360 for accessing couchdb
  file { 'couchdb.properties':
    path    => "${sw360_settings_path}/couchdb.properties",
    content => template('sw360/couchdb.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File['sw360-dir']
  }

  # central couchdb file ...
  file { 'couchdb_test.properties':
    path    => "${sw360_settings_path}/couchdb-test.properties",
    content => template('sw360/couchdb-test.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File['sw360-dir']
  }

  # another "central" couchdb file ...
  file { 'databasetest.properties':
    path    => "${sw360_settings_path}/databasetest.properties",
    content => template('sw360/databasetest.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File['sw360-dir']
  }

  # Configuration of the sw360 itself
  file { 'sw360.properties':
    path    => "${sw360_settings_path}/sw360.properties",
    content => template('sw360/sw360.properties.erb'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File['sw360-dir']
  }

  # creation of separate settings dir for authorization component
  file { 'sw360-authorization-dir':
    path    => "${sw360_settings_path}/authorization",
    owner   => 'siemagrant',
    group  => 'siemagrant',
    ensure => 'directory',
  }

  # Configuration of the sw360 rest api (spring stuff)
  file { 'application-auth.yml':
    path    => "${sw360_settings_path}/authorization/application.yml",
    content => template('sw360/application.yml.erb'),
    owner   => 'siemagrant',
    ensure  => present,
    require => File['sw360-authorization-dir']
  }

  ## todo setting for resource server for REST (runs with default settings)

  ###################
  ## Apache2 Setup ##
  ###################

  $apache2_cert_dir = '/etc/apache2/certs'
  $apache2_key = 'liferay.key'
  $apache2_cert = 'liferay.pem'

  file { 'apache2-certs':
    path   => "${apache2_cert_dir}",
    ensure => 'directory',
    owner  => 'root',
  }

  exec { 'generate-apache2-certs':
    command => "openssl req -newkey rsa:2048 -nodes -keyout ${apache2_key} -x509 -days 365 -out ${apache2_cert} -subj '/CN=liferay.localdomain'",
    cwd => "${apache2_cert_dir}",
    creates => ["${apache2_cert_dir}/${apache2_key}", "${apache2_cert_dir}/${apache2_cert}"],
    path => ['/usr/bin/'],
    require => File['apache2-certs'],
  }

  file { 'apache2-sw360.conf':
    path    => "/etc/apache2/sites-available/sw360.conf",
    content => template('sw360/apache2-sw360.conf.erb'),
    owner   => 'root',
    ensure  => 'present',
    require => Exec['generate-apache2-certs'],
  }

  file { 'apache2-default':
    path    => "/etc/apache2/sites-enabled/default",
    ensure  => 'absent',
  }

  file { 'apache2-sw360-link':
    path    => "/etc/apache2/sites-enabled/sw360.conf",
    target  => "/etc/apache2/sites-available/sw360.conf",
    ensure  => 'link',
    notify  => Service["apache2"], # Will cause the service to restart
    require => File['apache2-sw360.conf'],
  }

  # Restart apache2
  service { 'apache2':
    ensure  => "running",
    enable  => "true",
  }
}

include sw360single
