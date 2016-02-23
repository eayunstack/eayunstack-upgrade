class eayunstack::upgrade::ceilometer (
  $fuel_settings,
) {
  
  $packages = { controller => [
  							  'openstack-ceilometer-common', 'python-ceilometer',
							  'openstack-ceilometer-collector', 'openstack-ceilometer-alarm',
							  'openstack-ceilometer-notification', 'openstack-ceilometer-central', 
							  'openstack-ceilometer-api',
  							  ],
				compute    => [
				              'openstack-ceilometer-common', 'python-ceilometer',
							  'openstack-ceilometer-compute',
							  ],
 }
 if $eayunstack_node_role == 'controller' {
  
  package { $packages[controller]:
    ensure => latest,
  	      }

  augeas {'add-ceilometer-api':
   context => '/files/etc/ceilometer/ceilometer.conf',
   lens => 'Puppet.lns',
   incl => '/etc/ceilometer/ceilometer.conf',
   changes => [
   'set DEFAULT/api_workers  20',
		  ],
   onlyif => 'match DEFAULT/api_workers[.="20"] size < 1',
		 }

  $systemd_services = [
                      'openstack-ceilometer-alarm-notifier', 'openstack-ceilometer-api',
					  'openstack-ceilometer-collector', 'openstack-ceilometer-notification',
                      ],
  service { $systemd_services:
   ensure => running,
   enable => true,
          }

  $pcs_services = [
                  'p_openstack-ceilometer-central', 'p_openstack-ceilometer-alarm-evaluator',
				  ],
  service { $pcs_services:
   ensure => running,
   enable => true,
   hasstatus => true,
   hasrestart => false,
   provider => 'pacemaker',
         }

  } elsif $eayunstack_node_role == 'compute' {
  package { $packages[compute]:
   ensure => latest,
		  }
  $systemd_services = [
                      'openstack-ceilometer-compute',
					  ],
  service { $systemd_services:
   ensure => running,
   enable => true,
		  }
  }
}
