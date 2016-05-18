module Puppet::Parser::Functions
  newfunction(:modify_ceph_auth_info, :type => :rvalue) do |args|
    entity = args[0]
    daemon_type = args[1]
    old_cap = args[2]
    new_cap = args[3]
    old_caps = ''
    auth_list = `/usr/bin/ceph -f json auth list`.strip
    auth_json = JSON.parse(auth_list)
    auth_json['auth_dump'].each do |auth|
      if auth['entity'] == entity
        old_caps = auth['caps'][daemon_type]
      end
    end
    new_caps = old_caps.gsub(old_cap, new_cap)
    return new_caps
  end
end
