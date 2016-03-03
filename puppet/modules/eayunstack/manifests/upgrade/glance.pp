class eayunstack::upgrade::glance (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    $systemd_services = [
      'openstack-glance-api', 'openstack-glance-registry',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }

  }
  # There is nothing to do on ceph-osd or compute.
}
