module Puppet::Parser::Functions
  newfunction(:get_eayunstack_pkg_rel, :type => :rvalue) do |args|
    pkgname = args[0]
    script = <<ENDSCRIPT
import yum
import logging
logging.disable(logging.INFO)
yb = yum.YumBase()
yb.cleanExpireCache()
holder = yb.doPackageLists(patterns=['#{pkgname}'])
package = holder['available'][0] or holder['installed'][0] or None
if package:
    print package.printVer().split('-')[1].split('.eayunstack')[0]
else:
    print 0
END_SCRIPT

    `python -c "#{script}"`.strip!
  end
end
