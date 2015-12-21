class eayunstack::upgrade (
  $fuel_settings,
) {
  class { 'eayunstack::upgrade::ntp':
    fuel_settings => $fuel_settings,
  }
}
