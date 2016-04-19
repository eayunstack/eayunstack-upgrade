class eayunstack::upgrade::python-eventlet (
  $fuel_settings,
) {

  include eayunstack::upgrade::ceilometer
  include eayunstack::upgrade::neutron
  include eayunstack::upgrade::cinder
  include eayunstack::upgrade::nova
  include eayunstack::upgrade::glance
  include eayunstack::upgrade::keystone
  include eayunstack::upgrade::heat

  $packages = ['python-eventlet']

  # On nodes of all roles, python-eventlet is to be upgraded.
  package { $packages:
    ensure => latest,
  }

  if $eayunstack_node_role == 'controller' {

    $all_related_services = [
      # Ceilometer
      'openstack-ceilometer-alarm-notifier', 'openstack-ceilometer-api',
      'openstack-ceilometer-collector', 'openstack-ceilometer-notification',
      'openstack-ceilometer-central', 'openstack-ceilometer-alarm-evaluator',
      # Cinder
      'openstack-cinder-api', 'openstack-cinder-scheduler',
      'openstack-cinder-volume',
      # Glance
      'openstack-glance-api', 'openstack-glance-registry',
      # Heat
      'openstack-heat-api-cfn', 'openstack-heat-api-cloudwatch',
      'openstack-heat-api', 'openstack-heat-engine',
      # Keystone
      'openstack-keystone',
      # Neutron
      'neutron-server', 'neutron-qos-agent', 'neutron-metering-agent',
      'neutron-openvswitch-agent', 'neutron-l3-agent', 'neutron-dhcp-agent',
      'neutron-metadata-agent', 'neutron-lbaas-agent',
      # Nova
      'openstack-nova-api', 'openstack-nova-cert', 'openstack-nova-conductor',
      'openstack-nova-consoleauth', 'openstack-nova-novncproxy',
      'openstack-nova-objectstore', 'openstack-nova-scheduler',
    ]

    Package['python-eventlet'] ~>
      Service[$all_related_services]

  } elsif $eayunstack_node_role == 'compute' {

    $all_related_services = [
      # Ceilometer
      'openstack-ceilometer-compute',
      # Neutron
      'neutron-openvswitch-agent', 'neutron-qos-agent',
      # Nova
      'openstack-nova-compute',
    ]

    Package['python-eventlet'] ~>
      Service[$all_related_services]

    # There is no service on ceph-osd to be restarted.
  }

}
