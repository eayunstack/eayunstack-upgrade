class eayunstack::upgrade::http::http_ceilometer(
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {
    package { 'httpd':
      ensure => latest,
    }
    file { '/var/www/ceilometer/':
      ensure => directory,
      require => Package['httpd']
    }
    file { 'ceilometer.wsgi':
      path => '/var/www/ceilometer/ceilometer.wsgi',
      source => 'puppet:///modules/eayunstack/ceilometer.wsgi',
      require => File['/var/www/ceilometer/'],
    }

    file { 'http-ceilometer.conf':
      path => '/etc/httpd/conf.d/openstack-ceilometer.conf',
      ensure => file,
      content => template('eayunstack/ceilometer_http.erb'),
    }

    service { 'httpd':
      ensure => running,
      enable => true,
    }

    File['http-ceilometer.conf'] ~>
      Service['httpd']

  }
  # There is nothing to do on api in compute.
}
