class eayunstack::upgrade::cinder (
  $fuel_settings,
) {
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
