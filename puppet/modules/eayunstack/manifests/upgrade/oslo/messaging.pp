class eayunstack::upgrade::oslo::messaging (
  $fuel_settings,
) {

  # We need to use ensure_resource method of stdlib
  include stdlib

  $packages = ['python-oslo-messaging', 'python-kombu']

  # On nodes of all roles, oslo-messaging is to be upgraded.
  package { $packages:
    ensure => latest,
  }

  $services = { controller => { systemd => ['neutron-server',
                                            'neutron-qos-agent',
                                            'neutron-metering-agent',
                                            'openstack-nova-api',
                                            'openstack-nova-cert',
                                            'openstack-nova-conductor',
                                            'openstack-nova-consoleauth',
                                            'openstack-nova-novncproxy',
                                            'openstack-nova-objectstore',
                                            'openstack-nova-scheduler',
                                            'openstack-cinder-api',
                                            'openstack-cinder-volume',
                                            'openstack-cinder-scheduler',
                                            'openstack-heat-api-cfn',
                                            'openstack-heat-api-cloudwatch',
                                            'openstack-heat-api',
                                            'openstack-keystone',
                                            'openstack-glance-api',
                                            'openstack-glance-registry',
                                            'openstack-ceilometer-alarm-notifier',
                                            'openstack-ceilometer-api',
                                            'openstack-ceilometer-collector',
                                            'openstack-ceilometer-notification',
                                            ],
                                pcs     => ['neutron-openvswitch-agent',
                                            'neutron-l3-agent',
                                            'neutron-dhcp-agent',
                                            'neutron-metadata-agent',
                                            'neutron-lbaas-agent',
                                            'openstack-ceilometer-central',
                                            'openstack-ceilometer-alarm-evaluator',
                                            'openstack-heat-engine',
                                            ],
                              },
                compute    => { systemd => ['openstack-ceilometer-compute',
                                            'openstack-nova-compute',
                                            ]
                              },
              }

  if $eayunstack_node_role == 'controller' {

    # ensure_resource declare one resource only when it has not been declared.
    # 1. If we do it with "service {}", resource redeclaration error may be thrown.
    # 2. If we bypass declaration, and use "Service[]" directly, we can't ensure
    # the resource is declared before, which may cause error too.
    #
    # According to some opinion in the forum, like
    # https://groups.google.com/forum/?utm_medium=email&utm_source=footer#!msg/puppet-users/NFYrD7gdkew/fkTNrmRgfo0J
    # the using of ensure_resource is some kind of evil. Maybe we should switch to other better
    # solutions later.
    ensure_resource(service, $services[controller][systemd],
    {
      ensure => running,
      enable => true,
    })

    ensure_resource(service, $services[controller][pcs],
    {
      ensure => running,
      enable => true,
      hasstatus => true,
      hasrestart => false,
      provider => 'pacemaker',
    })

    Package['python-oslo-messaging'] ~>
      Service[$services[controller][systemd]]

    Package['python-oslo-messaging'] ~>
      Service[$services[controller][pcs]]

 } elsif $eayunstack_node_role == 'compute' {

    ensure_resource(service, $services[compute][systemd],
    {
      ensure => running,
      enable => true,
    })

    Package['python-oslo-messaging'] ~>
      Service[$services[compute][systemd]]

    # There is no service on ceph-osd to be restarted.
 }

}
