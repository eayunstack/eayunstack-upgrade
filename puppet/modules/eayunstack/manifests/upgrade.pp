class eayunstack::upgrade (
  $fuel_settings,
) {
  class { 'eayunstack::upgrade::ntp':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::cinder':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::nova':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::neutron':
    fuel_settings => $fuel_settings,
  }
  class { 'eayunstack::upgrade::oslo::messaging':
    fuel_settings => $fuel_settings,
  }
}
