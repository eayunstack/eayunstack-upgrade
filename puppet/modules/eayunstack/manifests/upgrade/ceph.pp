class eayunstack::upgrade::ceph (
  $fuel_settings,
) {
  $packages = [
    'ceph', 'ceph-common', 'ceph-deploy', 'libcephfs1', 'librados2',
    'librbd1', 'python-ceph-compat', 'python-cephfs', 'python-rados',
    'python-rbd',
  ]

  $lib_packages = [
    'librados2', 'librbd1', 'python-rados', 'python-rbd'
  ]

  if $eayunstack_node_role =~ /controller|ceph-osd|compute/ {
    package { $packages:
      ensure => latest,
    }
  }

  if $eayunstack_node_role == 'controller' {
    # just get current mon acl, without any modification
    $ceph_mon_caps = get_ceph_auth_info('client.compute', 'mon')
    # modify user 'compute''s access permission from 'rx' to 'rwx' for images pool
    $ceph_osd_caps = modify_ceph_auth_info('client.compute', 'osd', 'allow rx pool=images', 'allow rwx pool=images')
    exec {'reset-cephx-acl-for-user-compute':
      path      => '/usr/bin/',
      command   => "ceph auth caps client.compute mon '${ceph_mon_caps}' osd '${ceph_osd_caps}'",
      tries     => 10,
      try_sleep => 20,
    }

    # Ceph packages upgrade will affect these services
    $affected_services = [
      'openstack-cinder-volume',
      'openstack-cinder-backup',
    ]
    Package[$lib_packages] ~> Service[$affected_services]
  }
}
