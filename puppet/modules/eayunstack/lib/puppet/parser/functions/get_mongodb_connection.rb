module Puppet::Parser::Functions
  newfunction(:get_mongodb_connection, :type => :rvalue) do |args|
    mongo_ip = "#{args[0]}:27017"
    mongo_password = args[1]
    script = <<ENDSCRIPT
from pymongo import MongoClient

try:
    mc = MongoClient('mongodb://admin:#{mongo_password}@#{mongo_ip}/admin')
    doc = mc.admin.command('isMaster')
    hosts = doc.get('hosts', ['#{mongo_ip}'])
except:
    hosts = ['#{mongo_ip}']

print 'mongodb://ceilometer:%s@%s/ceilometer' % (
   '#{mongo_password}', ','.join(hosts)
)
END_SCRIPT

    `python -c "#{script}"`.strip!
  end
end
