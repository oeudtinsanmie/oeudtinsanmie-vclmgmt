require 'set'
module Puppet::Parser::Functions
  newfunction(:list_vlans, :type => :rvalue) do |args|
    poddefaults = args[0]
    pods 	      = args[1]
    private_if 	= args[2]
    ipmi_if     = args[3]
    list        = Set[]
    pods.each_value { |val| 
      if (val["private_hash"]["vlanid"] == nil) then
        if (poddefaults["private_hash"] != nil and poddefaults["private_hash"]["vlanid"] != nil) then
          list = list << "#{private_if}.#{poddefaults["private_hash"]["vlanid"]}" 
        else
          list = list << "#{private_if}" 
        end
      else
        list = list << "#{private_if}.#{val["private_hash"]["vlanid"]}" 
      end
      if (val["ipmi_hash"]["vlanid"] == nil) then
        if (poddefaults["ipmi_hash"] != nil and poddefaults["ipmi_hash"]["vlanid"] != nil) then
          list = list << "#{private_if}.#{poddefaults["ipmi_hash"]["vlanid"]}" 
        else
          list = list << "#{ipmi_if}" 
        end
      else
        list = list << "#{ipmi_if}.#{val["ipmi_hash"]["vlanid"]}" 
      end
    }
    list.to_a
  end
end
