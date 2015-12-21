module Puppet::Parser::Functions
  newfunction(:get_controllers, :type => :rvalue) do |args|
    controllers = []
    eayunstack_node_info_list = args[0]
    eayunstack_node_info_list.each_line do |node|
      fqdn,name,ip,role = node.strip.split(':')
      controllers.push(fqdn) if role == 'controller'
    end
    controllers
  end
end
