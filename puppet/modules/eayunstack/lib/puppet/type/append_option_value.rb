Puppet::Type.newtype(:append_option_value) do
  @doc = "Append value to the option"

  ensurable

  newparam(:section_option) do
    desc 'Section/setting name to manage from config'
    newvalues(/\S+\/\S+/)
  end

  newparam(:path, :namevar => true) do
    desc 'The path about the config file'
  end
  
  newproperty(:value) do
    desc 'The value of the setting to be defined.'
    munge do |value|
      value = value.to_s.strip
      value.capitalize! if value =~ /^(true|false)$/i
      value
    end
  end

  newparam(:append_to_list, :boolean => true) do
    desc 'Whether the specified value is to be appended to the current ones'
    newvalues(:true, :false)
    defaultto false
  end

end
