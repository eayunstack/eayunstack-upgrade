class eayunstack::upgrade::ceilometer (
  $fuel_settings,
) {
  $packages = { controller => [
                              'openstack-ceilometer-common', 'python-ceilometer',
                              'openstack-ceilometer-collector', 'openstack-ceilometer-alarm',
                              'openstack-ceilometer-notification', 'openstack-ceilometer-central',
                              'openstack-ceilometer-api',
                              ],
                compute    => [
                              'openstack-ceilometer-common', 'python-ceilometer',
                              'openstack-ceilometer-compute',
                              ],
  }

  if $eayunstack_node_role == 'controller' {
    package { $packages[controller]:
      ensure => latest,
    }
    $systemd_services = [
      'openstack-ceilometer-alarm-notifier', 'openstack-ceilometer-collector',
      'openstack-ceilometer-notification',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    $pcs_services = [
      'openstack-ceilometer-central', 'openstack-ceilometer-alarm-evaluator',
    ]
    service { $pcs_services:
      ensure => running,
      enable => true,
      hasstatus => true,
      hasrestart => false,
      provider => 'pacemaker',
    }

    service { 'openstack-ceilometer-api':
      ensure => stopped,
      enable => false,
    }

    file { '/var/www/ceilometer/':
      ensure => directory,
    }

    file { 'ceilometer.wsgi':
      path => '/var/www/ceilometer/ceilometer.wsgi',
      source => 'puppet:///modules/eayunstack/ceilometer.wsgi',
      require => File['/var/www/ceilometer/'],
    }

    file { 'openstack-ceilometer.conf':
      path => '/etc/httpd/conf.d/openstack-ceilometer.conf',
      ensure => file,
      content => template('eayunstack/ceilometer_http_conf.erb'),
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

    Package['openstack-ceilometer-alarm'] ~>
      Service['openstack-ceilometer-alarm-notifier']
    Package['openstack-ceilometer-notification'] ~>
      Service['openstack-ceilometer-notification']
    Package['openstack-ceilometer-collector'] ~>
      Service['openstack-ceilometer-collector']
    Package['openstack-ceilometer-api'] ~>
      Service['openstack-ceilometer-api'] ~>
        File['openstack-ceilometer.conf'] ~>
          Augeas['ceilometer-update-debug'] ~>
            Service['httpd']
    Package['openstack-ceilometer-central'] ~>
      Service['openstack-ceilometer-central']
    Package['openstack-ceilometer-alarm'] ~>
      Service['openstack-ceilometer-alarm-evaluator']

  } elsif $eayunstack_node_role == 'compute' {
    package { $packages[compute]:
      ensure => latest,
    }
    $systemd_services = [
      'openstack-ceilometer-compute',
    ]
    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    Package['openstack-ceilometer-compute'] ~>
      Service['openstack-ceilometer-compute']
  }
}
