class eayunstack::upgrade::neutron::eayunstack_1_0_1 {

  $package_name = "openstack-neutron"
  $ceil_release = "18"  # Eayunstack-building PR #36
  $available_release = get_eayunstack_pkg_rel($package_name)

  if versioncmp($available_release, $required_release) <= 0 {

    $changed_files = [
      'dhcp.py',
      'iptables_manager.py',
      'metering_iptables_driver.py',
      'qos_agent.py',
    ]
    file { $changed_files:
      ensure => file,
      backup => '.bak',
      mode => '0644',
      owner => 'root',
      group => 'root',
      require => Package['python-neutron'],
    }

    File['dhcp.py'] {
      path => '/usr/lib/python2.7/site-packages/neutron/agent/linux/dhcp.py',
      source => 'puppet:///modules/eayunstack/neutron/dhcp.py',
      notify => Service['neutron-dhcp-agent'],
    }

    File['iptables_manager.py'] {
      path => '/usr/lib/python2.7/site-packages/neutron/agent/linux/iptables_manager.py',
      source => 'puppet:///modules/eayunstack/neutron/iptables_manager.py',
      notify => [
        Service['neutron-metering-agent', 'neutron-l3-agent'],
      ],
    }
    File['metering_iptables_driver.py'] {
      path => '/usr/lib/python2.7/site-packages/neutron/services/metering/drivers/iptables/iptables_driver.py',
      source => 'puppet:///modules/eayunstack/neutron/metering_iptables_driver.py',
      notify => Service['neutron-metering-agent'],
    }
    File['qos_agent.py'] {
      path => '/usr/lib/python2.7/site-packages/neutron/services/qos/agents/qos_agent.py',
      source => 'puppet:///modules/eayunstack/neutron/qos_agent.py',
      notify => Service['neutron-qos-agent'],
    }

  }

}
