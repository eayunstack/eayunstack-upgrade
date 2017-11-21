class eayunstack::upgrade::eayunstack_notifier (
  $fuel_settings,
  $env_settings,
) {
  $nodes = $fuel_settings['nodes']
  $roles = node_roles($nodes, $fuel_settings['uid'])
  $controller_nodes = filter_nodes($nodes, 'role', 'controller')
  $primary_controller_nodes = filter_nodes($nodes, 'role', 'primary-controller')
  $rabbit_hosts = get_rabbit_hosts($controller_nodes, $primary_controller_nodes)
  $rabbit_userid = 'nova'
  $rabbit_password = $fuel_settings['rabbit']['password']
  $notification_topics = 'monitor'
  $package = 'eayunstack-notifier'
  $eayunstack_notifier_ak = $env_settings['eayunstack_notifier_ak']
  $eayunstack_notifier_sk = $env_settings['eayunstack_notifier_sk']
  $eayunstack_notifier_api_address = $env_settings['eayunstack_notifier_api_address']

  if 'compute' in $roles {

    augeas { 'update_compute_configuration_for_notifier':
      context => '/files/etc/nova/nova.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/nova/nova.conf',
      changes => [
        'set DEFAULT/notify_on_any_change True',
      ],
    }

    append_option_value { '/etc/nova/nova.conf':
      section_option => 'DEFAULT/notification_topics',
      value          => $notification_topics,
      append_to_list => true,
    }

    Augeas['update_compute_configuration_for_notifier'] ~>
      Service['openstack-nova-compute']

    Append_option_value['/etc/nova/nova.conf'] ~>
      Service['openstack-nova-compute']

  }
  if 'controller' in $roles or 'primary-controller' in $roles {

    package { $package:
      ensure => latest,
      notify => Service['eayunstack-notifier']
    }

    service { 'eayunstack-notifier':
      ensure => running,
      enable => true,
    }

    append_option_value { '/etc/cinder/cinder.conf':
      section_option => 'DEFAULT/notification_topics',
      value          => $notification_topics,
      append_to_list => true,
    }

    append_option_value { '/etc/glance/glance-api.conf':
      section_option => 'DEFAULT/notification_topics',
      value          => $notification_topics,
      append_to_list => true,
    }

    augeas { 'update_notifier_configuration':
      context => '/files/etc/eayunstack-notifier/eayunstack-notifier.conf',
      lens    => 'Puppet.lns',
      incl    => '/etc/eayunstack-notifier/eayunstack-notifier.conf',
      changes => [
        "set default/rabbit_hosts ${rabbit_hosts}",
        "set default/rabbit_userid ${rabbit_userid}",
        "set default/rabbit_password ${rabbit_password}",
        "set default/notification_topics ${notification_topics}",
        "set api/access_key ${eayunstack_notifier_ak}",
        "set api/secret_key ${eayunstack_notifier_sk}",
        "set api/api_address ${eayunstack_notifier_api_address}",
      ],
      require => Package['eayunstack-notifier'],
    }

    Append_option_value['/etc/cinder/cinder.conf'] ~>
      Service['openstack-cinder-volume']

    Append_option_value['/etc/glance/glance-api.conf'] ~>
      Service['openstack-glance-api']

    Augeas['update_notifier_configuration'] ~>
      Service['eayunstack-notifier']
  }
}
