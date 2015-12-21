require 'facter'

node_list_file = '/.eayunstack/node-list'
node_role_file = '/.eayunstack/node-role'

if File.exist?(node_list_file)
  Facter.add('eayunstack_node_info_list') do
    setcode { File.read(node_list_file) }
  end
end

if File.exist?(node_role_file)
  Facter.add('eayunstack_node_role') do
    setcode { File.read(node_role_file).strip }
  end
end
