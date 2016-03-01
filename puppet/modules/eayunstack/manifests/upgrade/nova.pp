class eayunstack::upgrade::nova (
  $fuel_settings,
) {

  $packages = { controller => [
                              'python-nova', 'openstack-nova-objectstore', 'openstack-nova-api',
                              'python-novaclient', 'openstack-nova-common', 'openstack-nova-console',
                              'openstack-nova-conductor', 'openstack-nova-novncproxy',
                              'openstack-nova-scheduler', 'openstack-nova-cert',
                              ],
                compute    => [
                              'python-novaclient', 'python-nova', 'openstack-nova-compute',
                              'openstack-nova-common',
                              ],
                ceph       => ['python-novaclient'],
  }
 
  $services = { controller => [
                              'openstack-nova-api', 'openstack-nova-cert', 'openstack-nova-conductor',
                              'openstack-nova-consoleauth', 'openstack-nova-novncproxy',
                              'openstack-nova-objectstore', 'openstack-nova-scheduler',
                              ],
                compute    => ['openstack-nova-compute'],
  }

  if $eayunstack_node_role == 'controller' {

    package { $packages[controller]:
      ensure => latest,
    } ~>
    service { $services[controller]:
      ensure => running,
      enable => true,
    }

  } elsif $eayunstack_node_role == 'compute' {

    package { $packages[compute]:
      ensure => latest,
    } ~>
    service { $services[compute]:
      ensure => running,
      enable => true,
    }

    augeas { 'change_cinder_catalog_info':
      context => '/files/etc/nova/nova.conf',
      lens => 'Puppet.lns',
      incl => '/etc/nova/nova.conf',
      changes => [
        "rm DEFAULT/cinder_catalog_info",
        "set cinder/catalog_info volumev2:cinderv2:internalURL",
      ],
      onlyif => 'match cinder/catalog_info[.="volumev2:cinderv2:internalURL"] size < 1',
    }

    Augeas['change_cinder_catalog_info'] ~> Service['openstack-nova-compute']

  } elsif $eayunstack_node_role == 'ceph-osd' {

    package { $packages[ceph]:
      ensure => latest,
    }

  }

}
