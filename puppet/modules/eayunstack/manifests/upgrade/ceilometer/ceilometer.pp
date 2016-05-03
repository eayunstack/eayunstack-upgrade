class eayunstack::upgrade::ceilometer::ceilometer (
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

    $mongo_password = $fuel_settings['ceilometer']['db_password']
    $mongo = get_server_by_role($fuel_settings['nodes'], ['primary-mongo'])
    $mongo_ip = $mongo['internal_address']
    $mongodb_connection = get_mongodb_connection($mongo_ip, $mongo_password)

    package { $packages[controller]:
      ensure => latest,
    }

    file { 'pipeline.yaml':
      path => '/etc/ceilometer/pipeline.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/pipeline.yaml',
      group => 'ceilometer',
      require => Package['openstack-ceilometer-common'],
      notify => [
        Service['openstack-ceilometer-notification'], Service['openstack-ceilometer-api'],
        Service['httpd'], Service['openstack-ceilometer-central'],
      ],
    }
    file { 'event_definitions.yaml':
      path => '/etc/ceilometer/event_definitions.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/event_definitions.yaml',
      group => 'ceilometer',
      require => Package['openstack-ceilometer-common'],
      notify => Service['openstack-ceilometer-notification'],
    }

    augeas { 'ceilometer-conf':
      context => '/files/etc/ceilometer/ceilometer.conf',
      lens => 'Puppet.lns',
      incl => '/etc/ceilometer/ceilometer.conf',
      changes => [
        "set DEFAULT/api_workers  $::processorcount",
        "set DEFAULT/debug False",
        "set DEFAULT/pipeline_cfg_file /etc/ceilometer/pipeline.yaml",
        "set api/pecan_debug False",
        "set database/connection $mongodb_connection",
        "set event/definitions_cfg_file /etc/ceilometer/event_definitions.yaml",
        "set notification/store_events True",
      ],
      require => [
        Package['openstack-ceilometer-common'],
        File['pipeline.yaml', 'event_definitions.yaml'],
      ],
      notify => [
        Service['openstack-ceilometer-api'],
        Service['openstack-ceilometer-central'],
        Service['openstack-ceilometer-collector'],
        Service['openstack-ceilometer-notification'],
        Service['httpd'],
      ],
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

    Package['openstack-ceilometer-alarm'] ~>
      Service['openstack-ceilometer-alarm-notifier']
    Package['openstack-ceilometer-notification'] ~>
      Service['openstack-ceilometer-notification']
    Package['openstack-ceilometer-collector'] ~>
      Service['openstack-ceilometer-collector']
    Package['openstack-ceilometer-api'] ~>
      Service['openstack-ceilometer-api']
    Package['openstack-ceilometer-central'] ~>
      Service['openstack-ceilometer-central']
    Package['openstack-ceilometer-alarm'] ~>
      Service['openstack-ceilometer-alarm-evaluator']

    Service['openstack-ceilometer-api'] {
      before => Service['httpd'],
    }
    Package['openstack-ceilometer-api'] {
      notify => Service['httpd'],
    }

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

    file { 'pipeline.yaml':
      path => '/etc/ceilometer/pipeline.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/pipeline.yaml',
      group => 'ceilometer',
      require => Package['openstack-ceilometer-common'],
      notify => Service['openstack-ceilometer-compute'],
    }

    augeas { 'ceilometer-pipeline':
      context => '/files/etc/ceilometer/ceilometer.conf',
      lens => 'Puppet.lns',
      incl => '/etc/ceilometer/ceilometer.conf',
      changes => [
        "set DEFAULT/pipeline_cfg_file /etc/ceilometer/pipeline.yaml",
      ],
      require => [
        Package['openstack-ceilometer-common'],
        File['pipeline.yaml'],
      ],
      notify => Service['openstack-ceilometer-compute'],
    }

    Package['openstack-ceilometer-compute'] ~>
      Service['openstack-ceilometer-compute']
  }
}
