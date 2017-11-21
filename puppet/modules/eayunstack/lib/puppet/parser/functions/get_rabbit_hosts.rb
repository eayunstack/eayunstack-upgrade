module Puppet::Parser::Functions
  newfunction(:get_rabbit_hosts, :type => :rvalue) do |args|
    controller_nodes = args[0]
    primary_controller_nodes = args[1]
    rabbit_hosts = "#{primary_controller_nodes[0]['internal_address']}:5673"
    controller_nodes.each do |controller_node|
      rabbit_hosts = "#{rabbit_hosts},#{controller_node['internal_address']}:5673"
    end
    rabbit_hosts
  end
end
