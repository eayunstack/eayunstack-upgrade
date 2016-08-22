class eayunstack::upgrade::haproxy::haproxy (
  $fuel_settings,
) {

  if $::eayunstack_node_role == 'controller' {

    package{ 'haproxy':
      ensure => latest,
    }

    $pcs_services = ['haproxy']
    service { $pcs_services:
      ensure => running,
      enable => true,
      hasstatus => true,
      hasrestart => false,
      provider => 'pacemaker',
    }

    file { 'haproxy_directory':
      ensure => directory,
      path => '/etc/haproxy/conf.d',
      require => Package['haproxy'],
    }

    file { 'haproxy_ceilometer':
      ensure => file,
      path => '/etc/haproxy/conf.d/140-ceilometer.cfg',
      content => template('eayunstack/haproxy_ceilometer.erb'),
      require => File['haproxy_directory'],
      notify => Service['haproxy'],
    }

    Package['haproxy'] ~>
      Service['haproxy']
  }
  # There is nothing to do on ceph-osd or compute.
}
