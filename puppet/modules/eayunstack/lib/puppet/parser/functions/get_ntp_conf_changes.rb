module Puppet::Parser::Functions
  newfunction(:get_ntp_conf_changes, :type => :rvalue) do |args|
    servers = args[0]
    params = args[1]
    ntp_conf_changes = ["rm server[.]"]
    servers.each do |server|
      ntp_conf_changes.push("set server[server = '#{server}'] #{server}")
      params.each do |key, value|
        ntp_conf_changes.push("set server[. = '#{server}']/#{key} '#{value}'")
      end
    end
    ntp_conf_changes
  end
end
