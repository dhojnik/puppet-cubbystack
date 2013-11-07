# == Class: cubbystack::horizon
#
# Configures Horizon
#
# === Parameters
#
# [*settings*]
#   A hash of key => value settings to go in cinder.conf
#
# [*config_file*]
#   The location of the local_settings.py file to deploy.
#   Defaults to 'modules/cubbystack/files/horizon/local_settings.py'
#   Static for now.
#
# [*web_user*]
#   The user that the web service runs as
#   Defaults to the params file
#
# [*web_group*]
#   The group that the web service runs as
#   Defaults to the params file
#
# === Example Usage
#
# Please see the `examples` directory.
#
class cubbystack::horizon (
  $package_ensure = latest,
  $config_file    = 'puppet:///modules/cubbystack/horizon/local_settings.py',
  $web_user       = $::cubbystack::params::horizon_apache_user,
  $web_group      = $::cubbystack::params::horizon_apache_group
) {

  include ::cubbystack::params

  package { 'horizon':
    name   => $::cubbystack::params::horizon_package_name,
    ensure => $package_ensure,
  }

  File {
    ensure => present,
    owner  => $web_user,
    group  => $web_group,
    mode   => '0640',
  }

  file { $::cubbystack::params::horizon_config_file:
    source => $config_file,
  }

}