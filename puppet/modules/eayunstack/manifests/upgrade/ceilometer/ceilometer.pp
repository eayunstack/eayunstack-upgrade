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
    package { $packages[controller]:
      ensure => latest,
    }

    file { 'pipeline.yaml':
      path => '/etc/ceilometer/pipeline.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/pipeline.yaml',
      group => 'ceilometer',
      notify => Service[
        'openstack-ceilometer-notification', 'httpd', 'openstack-ceilometer-central'
      ],
    }
    file { 'event_definitions.yaml':
      path => '/etc/ceilometer/event_definitions.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/event_definitions.yaml',
      group => 'ceilometer',
      notify => Service['openstack-ceilometer-notification'],
    }

    augeas { 'ceilometer-conf':
      context => '/files/etc/ceilometer/ceilometer.conf',
      lens => 'Puppet.lns',
      incl => '/etc/ceilometer/ceilometer.conf',
      changes => [
        "set DEFAULT/api_workers  $::processorcount",
        "set DEFAULT/debug False",
        "set api/pecan_debug False",
        "set DEFAULT/pipeline_cfg_file /etc/ceilometer/pipeline.yaml",
        "set event/definitions_cfg_file /etc/ceilometer/event_definitions.yaml",
        "set notification/store_events True",
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
      require => File['pipeline.yaml', 'event_definitions.yaml'],
    }

    Package['openstack-ceilometer-alarm'] ~>
      Service['openstack-ceilometer-alarm-notifier']
    Package['openstack-ceilometer-notification'] ~>
      Service['openstack-ceilometer-notification']
    Package['openstack-ceilometer-collector'] ~>
      Service['openstack-ceilometer-collector']
    Package['openstack-ceilometer-api'] ~>
      Augeas['ceilometer-conf'] ~>
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
      require => File['pipeline.yaml'],
    }

    file { 'pipeline.yaml':
      path => '/etc/ceilometer/pipeline.yaml',
      ensure => file,
      source => 'puppet:///modules/eayunstack/pipeline.yaml',
      group => 'ceilometer',
      notify => Service['openstack-ceilometer-compute'],
    }

    augeas { 'ceilometer-pipeline':
      context => '/files/etc/ceilometer/ceilometer.conf',
      lens => 'Puppet.lns',
      incl => '/etc/ceilometer/ceilometer.conf',
      changes => [
        "set DEFAULT/pipeline_cfg_file /etc/ceilometer/pipeline.yaml",
      ],
    }

    Package['openstack-ceilometer-compute'] ~>
      Augeas['ceilometer-pipeline'] ~>
        Service['openstack-ceilometer-compute']
  }
}
