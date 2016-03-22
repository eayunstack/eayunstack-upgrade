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
    file { 'ceilometer-haproxy':
      path => '/tmp/ceilometer-haproxy.sh',
      ensure => file,
      source => 'puppet:///modules/eayunstack/ceilometer-haproxy.sh',
    }

    exec { 'haproxy-ceilometer':
      command => 'sh /tmp/ceilometer-haproxy.sh',
      path => '/usr/bin/',
      require => File['ceilometer-haproxy'],
    }

    Package['haproxy'] ~>
      Exec['haproxy-ceilometer'] ~>
        Service['haproxy']
  }
  # There is nothing to do on ceph-osd or compute.
}
