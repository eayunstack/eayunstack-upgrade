require 'json'

module Puppet::Parser::Functions
  newfunction(:get_ceph_auth_info, :type => :rvalue) do |args|
    entity = args[0]
    daemon_type = args[1]
    caps = ''
    auth_list = `/usr/bin/ceph -f json auth list`.strip
    auth_json = JSON.parse(auth_list)
    auth_json['auth_dump'].each do |auth|
      if auth['entity'] == entity
        caps = auth['caps'][daemon_type]
      end
    end
    return caps
  end
end
