class eayunstack::upgrade::keystone (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    $systemd_services = [
      'openstack-keystone',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }

  }
  # There is nothing to do on ceph-osd or compute.
}
