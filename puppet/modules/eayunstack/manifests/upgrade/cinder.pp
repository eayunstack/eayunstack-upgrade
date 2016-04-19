class eayunstack::upgrade::cinder (
) {
  if $eayunstack_node_role == 'controller' {

    $cinder_packages = [
      'openstack-cinder', 'python-cinder', 'python-cinderclient',
    ]

    $cinder_services = [
      'openstack-cinder-api',
      'openstack-cinder-scheduler',
      'openstack-cinder-volume',
    ]
    service { $cinder_services:
      ensure => running,
      enable => true,
    }

  } else {

    $cinder_packages = [
      'python-cinder', 'python-cinderclient',
    ]
  }
}
