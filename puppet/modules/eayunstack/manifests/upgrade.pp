class eayunstack::upgrade (
  $fuel_settings,
) {
  class { 'eayunstack::upgrade::nova':
    fuel_settings => $fuel_settings,
  }
}
