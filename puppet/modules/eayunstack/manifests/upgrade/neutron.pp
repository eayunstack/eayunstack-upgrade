class eayunstack::upgrade::neutron (
  $fuel_settings,
) {

  if $eayunstack_node_role == 'controller' {

    $packages = [
      'python-neutron', 'openstack-neutron', 'openstack-neutron-ml2',
      'openstack-neutron-openvswitch', 'openstack-neutron-vpn-agent',
      'openstack-neutron-metering-agent', 'pptpd', 'python-neutronclient',
    ]
    package { $packages:
      ensure => latest,
    }

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

    exec { 'database-upgrade':
      command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
      path        => '/usr/bin',
      refreshonly => true,
      tries       => 10,
      try_sleep   => 20,
    }

    augeas { 'add-pptp-vpn-service-provider':
      context => '/files/etc/neutron/neutron.conf',
      lens => 'Puppet.lns',
      incl => '/etc/neutron/neutron.conf',
      changes => [
        'set service_providers/service_provider[last()+1] VPN:pptp:neutron.services.vpn.service_drivers.pptp.PPTPVPNDriver'
      ],
      onlyif => 'match service_providers/service_provider[.="VPN:pptp:neutron.services.vpn.service_drivers.pptp.PPTPVPNDriver"] size < 1',
    }

    augeas { 'add-pptp-vpn-device-driver':
      context => '/files/etc/neutron/l3_agent.ini',
      lens => 'Puppet.lns',
      incl => '/etc/neutron/l3_agent.ini',
      changes => [
        'set vpnagent/vpn_device_driver[last()+1] neutron.services.vpn.device_drivers.pptp.PPTPDriver'
      ],
      onlyif => 'match vpnagent/vpn_device_driver[.="neutron.services.vpn.device_drivers.pptp.PPTPDriver"] size < 1',
    }

    file { 'replace-neutron-l3-agent':
      path   => "/usr/bin/neutron-l3-agent",
      ensure => file,
      backup => '.bak',
      mode   => '0755',
      owner  => 'root',
      group  => 'root',
      source => "/usr/bin/neutron-vpn-agent"
    }

    file { 'ppp-dir':
      ensure => directory,
      path => '/etc/ppp',
      owner => 'neutron',
      group => 'root',
    }

    file { 'ppp-chap-secrets':
      ensure => file,
      path => '/etc/ppp/chap-secrets',
      mode => '0644',
      owner => 'neutron',
      group => 'neutron',
    }

    $ip_local_files = ['ip-up.local', 'ip-down.local']
    file { $ip_local_files:
      ensure => file,
      mode => '0755',
      owner => 'root',
      group => 'root',
    }
    File['ip-up.local'] {
      path => '/etc/ppp/ip-up.local',
      source => 'puppet:///modules/eayunstack/ip-up.local',
    }
    File['ip-down.local'] {
      path => '/etc/ppp/ip-down.local',
      source => 'puppet:///modules/eayunstack/ip-down.local',
    }

    Package['openstack-neutron-ml2'] {
      notify => [
        Augeas['add-pptp-vpn-service-provider'],
        Exec['database-upgrade'],
        Service['neutron-server'],
      ],
    }
    Augeas['add-pptp-vpn-service-provider'] ~> Service['neutron-server']
    Exec['database-upgrade'] ~> Service['neutron-server']

    Package['openstack-neutron-openvswitch'] ~>
      Service['neutron-openvswitch-agent']

    Package['openstack-neutron-vpn-agent'] ->
      Augeas['add-pptp-vpn-device-driver'] ~>
        Service['neutron-l3-agent']
    Package['openstack-neutron-vpn-agent'] ~>
      File['replace-neutron-l3-agent'] ~>
        Service['neutron-l3-agent']
    Package['openstack-neutron-vpn-agent'] ~> Service['neutron-l3-agent']

    Package['openstack-neutron-metering-agent'] ~>
      Service['neutron-metering-agent']

    Package['openstack-neutron'] {
      notify => [
        Service['neutron-dhcp-agent'], Service['neutron-metadata-agent'],
        Service['neutron-lbaas-agent'], Service['neutron-qos-agent'],
      ],
    }

    Service['neutron-server'] {
      before => [
        Service['neutron-openvswitch-agent'], Service['neutron-l3-agent'],
        Service['neutron-dhcp-agent'], Service['neutron-metadata-agent'],
        Service['neutron-lbaas-agent'], Service['neutron-qos-agent'],
        Service['neutron-metering-agent'],
      ],
    }

    Service['neutron-openvswitch-agent'] {
      before => [Service['neutron-l3-agent'], Service['neutron-dhcp-agent'],],
    }

    Service['neutron-l3-agent'] {
      before => [
        Service['neutron-lbaas-agent'], Service['neutron-qos-agent'],
      ],
    }

  } elsif $eayunstack_node_role == 'compute' {

    $packages = [
      'python-neutron', 'openstack-neutron', 'openstack-neutron-ml2',
      'openstack-neutron-openvswitch', 'python-neutronclient',
    ]
    package { $packages:
      ensure => latest,
    }

    $systemd_services = [
      'neutron-openvswitch-agent', 'neutron-qos-agent',
    ]
    service { $systemd_services:
      ensure => running,
      enable => true,
    }

    Package['openstack-neutron-openvswitch'] ~>
      Service['neutron-openvswitch-agent'] ->
        Service['neutron-qos-agent']

    Package['openstack-neutron'] ~>
      Service['neutron-qos-agent']

  }

}
