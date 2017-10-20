class eayunstack::upgrade::cinder (
  $fuel_settings,
) {

  $admin_username = 'nova'
  $admin_password = $fuel_settings['nova']['user_password']
  $admin_tenant_name = 'services'
  $admin_auth_url = "http://${fuel_settings['management_vip']}:35357/v2.0"

  if $eayunstack_node_role == 'controller' {

    $cinder_packages = [
      'openstack-cinder', 'python-cinder', 'python-cinderclient',
    ]
    package { $cinder_packages:
      ensure => latest,
    }

    $cinder_services = [
      'openstack-cinder-api',
      'openstack-cinder-scheduler',
      'openstack-cinder-volume',
      'openstack-cinder-backup',
    ]
    service { $cinder_services:
      ensure => running,
      enable => true,
    }

    augeas { 'add-nova-admin-info':
      context => '/files/etc/cinder/cinder.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/cinder/cinder.conf',
      changes => [
        "set DEFAULT/os_privileged_user_name ${admin_username}",
        "set DEFAULT/os_privileged_user_password ${admin_password}",
        "set DEFAULT/os_privileged_user_tenant ${admin_tenant_name}",
        "set DEFAULT/os_privileged_user_auth_url ${admin_auth_url}",
      ],
    }

    augeas { 'rbd-flatten-volume-from-snapshot':
      context => '/files/etc/cinder/cinder.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/cinder/cinder.conf',
      changes => [
        'setm *[volume_driver = "cinder.volume.drivers.rbd.RBDDriver"] rbd_flatten_volume_from_snapshot True',
      ],
      notify  => Service['openstack-cinder-volume'],
    }

    exec {'cinder-db-sync':
      command     => 'cinder-manage db sync',
      path        => '/usr/bin',
      user        => 'cinder',
      refreshonly => true,
      tries       => 3,
      try_sleep   => 20,
    }

    Package['openstack-cinder'] {
      notify => [
        Exec['cinder-db-sync'],
        Augeas['add-nova-admin-info'],
        Augeas['rbd-flatten-volume-from-snapshot'],
        Service['openstack-cinder-api'],
        Service['openstack-cinder-scheduler'],
        Service['openstack-cinder-volume'],
        Service['openstack-cinder-backup'],
      ]
    }

    Exec['cinder-db-sync'] {
      notify => [
        Service['openstack-cinder-api'],
        Service['openstack-cinder-scheduler'],
        Service['openstack-cinder-volume'],
        Service['openstack-cinder-backup'],
      ]
    }

    Augeas['add-nova-admin-info'] {
      notify => [
        Service['openstack-cinder-api'],
        Service['openstack-cinder-scheduler'],
        Service['openstack-cinder-volume'],
        Service['openstack-cinder-backup'],
      ]
    }

    Service['openstack-cinder-api'] {
      before => [
        Service['openstack-cinder-scheduler'],
        Service['openstack-cinder-volume'],
        Service['openstack-cinder-backup'],
      ]
    }
  } else {

    $cinder_packages = [
      'python-cinder', 'python-cinderclient',
    ]
    package { $cinder_packages:
      ensure => latest,
    }
  }
}
