class eayunstack::generic {

  $openstack_services = {
    'controller' => [
      # Ceilometer
      'openstack-ceilometer-alarm-notifier', 'httpd',
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
    ],
    'compute' => [
      # Ceilometer
      'openstack-ceilometer-compute',
      # Neutron
      'neutron-openvswitch-agent', 'neutron-qos-agent',
      # Nova
      'openstack-nova-compute',
    ],
  }
}
