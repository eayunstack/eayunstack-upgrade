class eayunstack::upgrade::heat (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    if $fuel_settings['deployment_mode'] == 'ha_compact' {
      $systemd_services = [
        'openstack-heat-api-cfn', 'openstack-heat-api-cloudwatch',
        'openstack-heat-api'
      ]
      $pcs_services = [
        'openstack-heat-engine',
      ]
    } else {
      $systemd_services = [
        'openstack-heat-api-cfn', 'openstack-heat-api-cloudwatch',
        'openstack-heat-api', 'openstack-heat-engine',
      ]
      $pcs_services = []
    }

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
