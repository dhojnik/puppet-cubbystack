# == Class: cubbystack::heat::api_cloudwatch
#
# Configures the heat-api_cloudwatch package and service
#
# === Parameters
#
# [*package_ensure*]
#   The status of the heat-api_cloudwatch package
#   Defaults to latest
#
# [*service_enable*]
#   The status of the heat-api_cloudwatch service
#   Defaults to true
#
# [*service_ensure*]
#   The run status of the heat-api_cloudwatch service
#   Defaults to running
#
class cubbystack::heat::api_cloudwatch (
  $package_ensure = latest,
  $service_enable = true,
  $service_ensure = 'running'
) {

  include ::cubbystack::heat

  cubbystack::functions::generic_service { 'heat-api_cloudwatch':
    service_enable => $service_enable,
    service_ensure => $service_ensure,
    package_ensure => $package_ensure,
    package_name   => $::cubbystack::params::heat_api_cloudwatch_package_name,
    service_name   => $::cubbystack::params::heat_api_cloudwatch_service_name,
    tags           => $::cubbystack::heat::tags,
  }

}