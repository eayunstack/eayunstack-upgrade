Puppet::Type.type(:append_option_value).provide(
  :ini_setting,
  :parent => Puppet::Type.type(:ini_setting).provider(:ruby)
) do

  def section
    resource[:section_option].split('/', 2).first
  end

  def setting
    resource[:section_option].split('/', 2).last
  end

  def separator
    '='
  end

  def file_path
    resource[:path]
  end

  def create
    append_value
    super
  end

  def value=(value)
    append_value
    super
  end

  private
  def append_value
    if resource[:append_to_list] and exists?
      c_list = value.strip.split(',')
      resource[:value] = c_list.push(resource[:value]).uniq.join(',')
    end
  end

end
