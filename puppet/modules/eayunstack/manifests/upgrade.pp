class eayunstack::upgrade (
  $fuel_settings,
) {
  class { 'eayunstack::upgrade::python-eventlet':
    fuel_settings => $fuel_settings,
  }
}
