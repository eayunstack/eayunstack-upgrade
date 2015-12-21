$fuel_settings = parseyaml($astute_settings_yaml)

if $fuel_settings {
  class { 'eayunstack::upgrade':
    fuel_settings => $fuel_settings,
  }
}
