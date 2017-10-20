class eayunstack::upgrade::auto_evacuate::auto_evacuate (
  $fuel_settings,
) {
  $nodes = $fuel_settings['nodes']
  $control_nodes = filter_nodes($nodes, 'role', 'controller')
  $deployment_mode = $fuel_settings['deployment_mode']

  if $deployment_mode == 'multinode' {
    $storage_ip1 = $control_nodes[0]['storage_address']
    $host_names = [$control_nodes[0]['fqdn']]
    $bootstrap_expect = 1
    $storage_ips = [$storage_ip1]
  }
  else {
    $first_node = filter_nodes($nodes, 'role', 'primary-controller')
    $storage_ip1 = $first_node[0]['storage_address']
    $storage_ip2 = $control_nodes[0]['storage_address']
    $storage_ip3 = $control_nodes[1]['storage_address']
    $host_names = [$first_node[0]['fqdn'], $control_nodes[0]['fqdn'], $control_nodes[1]['fqdn']]
    $bootstrap_expect = 3
    $storage_ips = [$storage_ip1, $storage_ip2, $storage_ip3]
  }

  $host_name = $fuel_settings['fqdn']
  $local_ips = filter_nodes($nodes, 'fqdn', $host_name)
  $storage_ip = $local_ips[0]['storage_address']
  $auth_url = "http://${fuel_settings['management_vip']}:5000/v2.0"

  if ($host_name in $host_names) or $eayunstack_node_role == 'compute' {
    package { 'consul':
      ensure => latest,
    }

    file { 'consul_config_dictory':
      ensure => directory,
      path   => '/etc/consul/storage',
    }

    file { 'consul_config_file':
      ensure  => file,
      path    => '/etc/consul/storage/consul.json',
      content => template('eayunstack/consul.erb'),
    }

    file { 'consul_sysconfig_file':
      ensure  => file,
      path    => '/etc/sysconfig/consul',
      content => 'CMD_OPTS="agent -config-dir=/etc/consul/storage -rejoin"',
    }

    file { 'consul_lib_dictory':
      ensure => directory,
      path   => '/var/lib/consul',
      owner  => 'consul',
      group  => 'consul',
    }

    service { 'consul':
      ensure => running,
      enable => true,
    }

    firewall { '830 consul port':
      dport  => [8300, 8301, 8302, 8400, 8500],
      proto  => 'tcp',
      action => 'accept',
    }

    Package['consul'] ->
      File['consul_config_dictory'] ->
        File['consul_config_file'] ~>
          Service['consul']

    Package['consul'] -> File['consul_sysconfig_file'] ~> Service['consul']
    Package['consul'] -> File['consul_lib_dictory'] -> Service['consul']
    Package['consul'] ~> Service['consul']

    if $host_name in $host_names {
      package { 'eayunstack-auto-evacuate':
        ensure => latest,
      }

      augeas { 'evacuate_config_file':
        context => '/files/etc/autoevacuate/evacuate.conf',
        lens    => 'Puppet.lns',
        incl    => '/etc/autoevacuate/evacuate.conf',
        changes => "set novaclient/auth_url ${auth_url}",
      }

      service { 'eayunstack-auto-evacuate':
        ensure => running,
        enable => true,
      }

      Package['eayunstack-auto-evacuate'] ->
        Augeas['evacuate_config_file'] ~>
          Service['eayunstack-auto-evacuate']

      Package['eayunstack-auto-evacuate'] ~> Service['eayunstack-auto-evacuate']
    }
  }
}
