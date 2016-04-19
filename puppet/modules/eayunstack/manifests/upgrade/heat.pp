class eayunstack::upgrade::heat (
) {

  if $::eayunstack_node_role == 'controller' {

    $systemd_services = [
      'openstack-heat-api-cfn', 'openstack-heat-api-cloudwatch',
      'openstack-heat-api'
    ]
    $pcs_services = [
      'openstack-heat-engine',
    ]

    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    service { $pcs_services:
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => false,
      provider   => 'pacemaker',
    }

  }
  # There is nothing to do on ceph-osd or compute.
}
