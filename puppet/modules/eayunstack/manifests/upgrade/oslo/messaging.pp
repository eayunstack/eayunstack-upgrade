class eayunstack::upgrade::oslo::messaging (
  $fuel_settings,
) {

  $packages = ['python-oslo-messaging', 'python-kombu']

  # On nodes of all roles, oslo-messaging is to be upgraded.
  package { $packages:
    ensure => latest,
  }

  if $eayunstack_node_role == 'controller' {

    Package['python-oslo-messaging'] ~>
      Service[$::eayunstack::generic::openstack_services['controller']]

  } elsif $eayunstack_node_role == 'compute' {

    Package['python-oslo-messaging'] ~>
      Service[$::eayunstack::generic::openstack_services['compute']]

    # There is no service on ceph-osd to be restarted.
  }

}
