module Puppet::Parser::Functions
  newfunction(:list_vlans, :type => :rvalue) do |args|
    pods 	= args[0]
    private_if 	= args[1]
    ipmi_if 	= args[2]
    list 	= Array.new
    pods.each_value { |val| 
      if val["private_hash"]["vlanid"] == nil
        list = list << "#{private_if}"
      else
        list = list << "#{private_if}.#{val["private_hash"]["vlanid"]}"
      end
      if val["ipmi_hash"]["vlanid"] == nil
        list = list << "#{ipmi_if}"
      else
        list = list << "#{ipmi_if}.#{val["ipmi_hash"]["vlanid"]}"
      end
    }
    list.uniq
  end
end
