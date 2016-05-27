class eayunstack::upgrade::neutron::pptpvpn {

  $package_name = "openstack-neutron"
  $required_release = "19"  # Eayunstack-building PR #36
  $available_release = get_eayunstack_pkg_rel($package_name)

  if versioncmp($available_release, $required_release) >= 0 {

    $packages = ['pptpd']
    package { $packages:
      ensure => latest,
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
      source => 'puppet:///modules/eayunstack/neutron/ip-up.local',
    }
    File['ip-down.local'] {
      path => '/etc/ppp/ip-down.local',
      source => 'puppet:///modules/eayunstack/neutron/ip-down.local',
    }

    Package['openstack-neutron-ml2'] ->
      Augeas['add-pptp-vpn-service-provider'] ~>
        Service['neutron-server']

    Package['openstack-neutron-vpn-agent'] ->
      Augeas['add-pptp-vpn-device-driver'] ~>
        Service['neutron-l3-agent']

  }

}
