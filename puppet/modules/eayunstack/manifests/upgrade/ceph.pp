class eayunstack::upgrade::ceph (
  $fuel_settings,
) {
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
  }
}
