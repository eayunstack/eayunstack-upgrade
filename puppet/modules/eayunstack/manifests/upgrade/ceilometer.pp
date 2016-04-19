class eayunstack::upgrade::ceilometer (
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
    $systemd_services = [
      'openstack-ceilometer-alarm-notifier', 'openstack-ceilometer-api',
      'openstack-ceilometer-collector', 'openstack-ceilometer-notification',
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

  } elsif $eayunstack_node_role == 'compute' {
    $systemd_services = [
      'openstack-ceilometer-compute',
    ]
    service { $systemd_services:
      ensure => running,
      enable => true,
    }
  }
}
