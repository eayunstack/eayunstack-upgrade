class eayunstack::upgrade (
  $fuel_settings,
  $env_settings,
) {
  include eayunstack::generic

  class { 'eayunstack::upgrade::auto_evacuate::auto_evacuate':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::ceilometer::ceilometer':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::cinder':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::eayunstack_notifier':
    fuel_settings => $fuel_settings,
    env_settings  => $env_settings,
  }
  class { 'eayunstack::upgrade::glance':
    fuel_settings => $fuel_settings,
  }
  if $fuel_settings['deployment_mode'] == 'ha_compact' {
    class { 'eayunstack::upgrade::haproxy::haproxy':
      fuel_settings => $fuel_settings,
    }
  }
  class { 'eayunstack::upgrade::heat':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::http::http_ceilometer':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::keystone':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::neutron':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::nova':
    fuel_settings => $fuel_settings,
    env_settings  => $env_settings,
  }
  class { 'eayunstack::upgrade::ntp':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::oslo::messaging':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::python_eventlet':
    fuel_settings => $fuel_settings,
  }
}
