class eayunstack::upgrade::consul::consul (
  $fuel_settings,
) {
  $nodes = $fuel_settings['nodes']
  $node = filter_nodes($nodes, 'role', 'controller')
  $first_node = filter_nodes($nodes, 'role', 'primary-controller')
  $storage_ip1 = $first_node[0]['storage_address']
  $storage_ip2 = $node[0]['storage_address']
  $storage_ip3 = $node[1]['storage_address']
  $host_name1 = $first_node[0]['fqdn']
  $host_name2 = $node[0]['fqdn']
  $host_name3 = $node[1]['fqdn']
  $host_names = [$host_name1, $host_name2, $host_name3]
  $host_name = $fuel_settings['fqdn']
  $local_ips = filter_nodes($nodes, 'fqdn', $host_name)
  $storage_ip = $local_ips[0]['storage_address']

  if $eayunstack_node_role == 'controller' {
    if $host_name in $host_names {
      package { 'consul':
        ensure => present,
      }
      file { '/etc/consul/consul.json':
        ensure  => file,
        require => Package['consul'],
        notify  => Service['consul'],
        content => template('eayunstack/consul.erb')
      }
      file { '/etc/sysconfig/consul':
        ensure  => file,
        require => Package['consul'],
        content => 'CMD_OPTS="agent -config-dir=/etc/consul/ -rejoin"',
        notify  => Service['consul'],
      }
      file { '/var/lib/consul':
        ensure  => directory,
        require => Package['consul'],
        owner   => 'consul',
        group   => 'consul',
        notify  => Service['consul'],
      }
      service { 'consul':
        ensure => running,
        enable => true,
      }
    }
  }
}
