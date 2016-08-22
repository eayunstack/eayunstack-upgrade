class eayunstack::upgrade::glance (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    $glance_packages = [
      'python-glance', 'python-glanceclient',
      'python-glance-store', 'openstack-glance',
    ]
    package { $glance_packages:
      ensure => latest,
    }

    augeas { 'glance-api':
      context => '/files/etc/glance/glance-api.conf',
      lens => 'Puppet.lns',
      incl => '/etc/glance/glance-api.conf',
      changes => [
        'set DEFAULT/notification_driver messaging',
      ],
      require => Package['openstack-glance'],
      notify => Service['openstack-glance-api'],
    }

    augeas { 'glance-registry':
      context => '/files/etc/glance/glance-registry.conf',
      lens => 'Puppet.lns',
      incl => '/etc/glance/glance-registry.conf',
      changes => [
        'set DEFAULT/notification_driver messaging',
      ],
      require => Package['openstack-glance'],
      notify => Service['openstack-glance-registry'],
    }
    $systemd_services = [
      'openstack-glance-api', 'openstack-glance-registry',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    Package['openstack-glance'] ~>
      Service['openstack-glance-registry']
    Package['openstack-glance'] ~>
      Service['openstack-glance-api']

  }
  # There is nothing to do on ceph-osd or compute.
}
