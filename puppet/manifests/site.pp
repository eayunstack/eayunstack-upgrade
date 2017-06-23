$fuel_settings = parseyaml($astute_settings_yaml)
$env_settings = parseyaml($env_settings_yaml)

if $fuel_settings {
  class { 'eayunstack::upgrade':
    fuel_settings => $fuel_settings,
    env_settings  => $env_settings,
  }
}
