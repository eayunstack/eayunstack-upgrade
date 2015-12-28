class eayunstack::upgrade::ntp (
  $fuel_settings,
) {

  service { 'ntpd':
    enable => true,
    ensure => 'running',
  }

  package { 'ntp':
    ensure => latest,
  }

  if $eayunstack_node_role == 'controller' {
    $servers = ['0.pool.ntp.org', '1.pool.ntp.org', '2.pool.ntp.org']
    $params = {'iburst' => '', 'minpoll' => '3', 'maxpoll' => '9'}
  } else {
    $servers = get_controllers($eayunstack_node_info_list)
    $params = {'burst' => '',  'iburst' => ''}
  }

  augeas { 'ntp.conf':
    context => '/files/etc/ntp.conf',
    changes => get_ntp_conf_changes($servers, $params),
  }

  Package['ntp'] ~> Service['ntpd']
  Package['ntp'] -> Augeas['ntp.conf'] ~> Service['ntpd']

}
