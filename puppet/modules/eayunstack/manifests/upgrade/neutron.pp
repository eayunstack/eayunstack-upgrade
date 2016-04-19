class eayunstack::upgrade::neutron (
) {

  if $eayunstack_node_role == 'controller' {

    $packages = [
      'python-neutron', 'openstack-neutron', 'openstack-neutron-ml2',
      'openstack-neutron-openvswitch', 'openstack-neutron-vpn-agent',
      'openstack-neutron-metering-agent', 'pptpd', 'python-neutronclient',
    ]

    $systemd_services = [
      'neutron-server', 'neutron-qos-agent', 'neutron-metering-agent',
    ]
    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    $pcs_services = [
      'neutron-openvswitch-agent', 'neutron-l3-agent', 'neutron-dhcp-agent',
      'neutron-metadata-agent', 'neutron-lbaas-agent',
    ]
    service { $pcs_services:
      ensure => running,
      enable => true,
      hasstatus => true,
      hasrestart => false,
      provider => 'pacemaker',
    }

  } elsif $eayunstack_node_role == 'compute' {

    $packages = [
      'python-neutron', 'openstack-neutron', 'openstack-neutron-ml2',
      'openstack-neutron-openvswitch', 'python-neutronclient',
    ]

    $systemd_services = [
      'neutron-openvswitch-agent', 'neutron-qos-agent',
    ]
    service { $systemd_services:
      ensure => running,
      enable => true,
    }

  }

}
