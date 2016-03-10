class eayunstack::upgrade::http::http_ceilometer(
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    file { '/var/www/ceilometer/':
      ensure => directory,
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
    augeas { 'ceilometer-debug':
      context => '/files/etc/ceilometer/ceilometer.conf',
      lens => 'Puppet.lns',
      incl => '/etc/ceilometer/ceilometer.conf',
      changes => [
        "set default/debug False",
        "set api/pecan_debug False",
      ],
    }
    service { 'httpd':
      ensure => running,
      enable => true,
    }

    File['http-ceilometer.conf'] ~>
      Augeas['ceilometer-debug'] ~>
        Service['httpd']

  }
  # There is nothing to do on api in compute.
}
