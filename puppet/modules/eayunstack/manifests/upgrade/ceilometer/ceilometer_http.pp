class eayunstack::upgrade::glance (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    service { 'openstack-ceilometer-api':
      ensure => stopped,
      enable => false,
    }

    file { '/var/www/ceilometer/':
      ensure => directory,
    }
    file { 'app.wsgi':
      path => '/var/www/ceilometer/app.wsgi',
      source => 'puppet:///modules/eayunstack/app.wsgi',
      require => File['/var/www/ceilometer/'],
    }

    file { 'openstack-ceilometer.conf':
      path => '/etc/httpd/conf.d/openstack-ceilometer.conf',
      ensure => file,
      content => template('eayunstack/ceilometer_http.conf.erb'),
    }
    augeas { 'ceilometer-update-debug':
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

    File['openstack-ceilometer.conf'] ~>
      Augeas['ceilometer-update-debug'] ~>
        Service['httpd']

  }
  # There is nothing to do on api in compute.
}
