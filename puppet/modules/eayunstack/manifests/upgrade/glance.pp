class eayunstack::upgrade::glance (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {
    augeas { 'glance-api':
      context => '/files/etc/glance/glance-api.conf',
      lens => 'Puppet.lns',
      incl => '/etc/glance/glance-api.conf',
      changes => [
        "set DEFAULT/notification_driver messaging",
      ],
    }

    augeas { 'glance-registry':
      context => '/files/etc/glance/glance-registry.conf',
      lens => 'Puppet.lns',
      incl => '/etc/glance/glance-registry.conf',
      changes => [
        "set DEFAULT/notification_driver messaging",
      ],
    }
    $systemd_services = [
      'openstack-glance-api', 'openstack-glance-registry',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }
    Augeas['glance-api'] ~>
      Service['openstack-glance-api']
    Augeas['glance-registry'] ~>
      Service['openstack-glance-registry']

  }
  # There is nothing to do on ceph-osd or compute.
}
