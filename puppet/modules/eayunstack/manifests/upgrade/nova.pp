class eayunstack::upgrade::nova (
  $fuel_settings,
  $env_settings,
) {
  $admin_auth_url = "http://${fuel_settings['management_vip']}:35357/v2.0"
  $admin_username = 'cinder'
  $admin_password = $fuel_settings['cinder']['user_password']
  $admin_tenant_name = 'services'
  # reclaim interval is 10 days.
  $reclaim_instance_interval = '864000'
  if $env_settings and has_key($env_settings, 'novncproxy_base_url') {
    $novncproxy_base_url = $env_settings['novncproxy_base_url']
  } else {
    $novncproxy_base_url = "https://${fuel_settings['public_vip']}:6080/vnc_auto.html"
  }
  $quota_key_pairs = '-1'

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

    augeas { 'add_cinder_admin_info':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set cinder/admin_auth_url ${admin_auth_url}",
        "set cinder/admin_username ${admin_username}",
        "set cinder/admin_password ${admin_password}",
        "set cinder/admin_tenant_name ${admin_tenant_name}",
      ],
      onlyif  => "match cinder/admin_username[.=\"${admin_username}\"] size < 1",
    }

    augeas { 'set_reclaim_instance_interval':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set DEFAULT/reclaim_instance_interval ${reclaim_instance_interval}",
      ],
    }

    augeas { 'resize_quota_key_pairs':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set DEFAULT/quota_key_pairs ${quota_key_pairs}",
      ],
    }

    Package['python-nova'] {
      notify => [
        Augeas['add_cinder_admin_info'],
        Augeas['set_reclaim_instance_interval'],
        Augeas['resize_quota_key_pairs'],
      ],
    }
    Augeas['add_cinder_admin_info'] {
      notify => [
        Service['openstack-nova-api'],
        Service['openstack-nova-conductor'],
      ],
    }
    Augeas['set_reclaim_instance_interval'] {
      notify => [
        Service['openstack-nova-api'],
        Service['openstack-nova-conductor'],
      ],
    }
    Augeas['resize_quota_key_pairs'] {
      notify => [
        Service['openstack-nova-api'],
      ],
    }

  } elsif $eayunstack_node_role == 'compute' {

    package { $packages[compute]:
      ensure => latest,
    } ~>
    service { $services[compute]:
      ensure => running,
      enable => true,
    }

    augeas { 'add_cinder_admin_info':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set cinder/admin_auth_url ${admin_auth_url}",
        "set cinder/admin_username ${admin_username}",
        "set cinder/admin_password ${admin_password}",
        "set cinder/admin_tenant_name ${admin_tenant_name}",
      ],
      onlyif  => "match cinder/admin_username[.=\"${admin_username}\"] size < 1",
    }

    augeas { 'change_cinder_catalog_info':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        'rm DEFAULT/cinder_catalog_info',
        'set cinder/catalog_info volumev2:cinderv2:internalURL',
      ],
      onlyif  => 'match cinder/catalog_info[.="volumev2:cinderv2:internalURL"] size < 1',
    }

    augeas { 'set_reclaim_instance_interval':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set DEFAULT/reclaim_instance_interval ${reclaim_instance_interval}",
      ],
    }

    Package['python-nova'] {
      notify => [
        Augeas['change_cinder_catalog_info'],
        Augeas['add_cinder_admin_info'],
        Augeas['set_reclaim_instance_interval'],
      ],
    }

    augeas { 'set_novnc_https':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        "set DEFAULT/novncproxy_base_url ${novncproxy_base_url}",
      ],
    }

    Augeas['change_cinder_catalog_info'] ~> Service['openstack-nova-compute']
    Augeas['add_cinder_admin_info'] ~> Service['openstack-nova-compute']
    Augeas['set_reclaim_instance_interval'] ~> Service['openstack-nova-compute']
    Augeas['set_novnc_https'] ~> Service['openstack-nova-compute']

  } elsif $eayunstack_node_role == 'ceph-osd' {

    package { $packages[ceph]:
      ensure => latest,
    }

  }

}
