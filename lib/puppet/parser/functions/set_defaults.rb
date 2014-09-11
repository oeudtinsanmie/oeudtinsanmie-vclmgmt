module Puppet::Parser::Functions
  newfunction(:set_defaults, :type => :rvalue) do |args|
    pods 		= args[0]
    poddefaults 	= args[1]
    masterdefaults 	= args[2]

    private_default = masterdefaults["private_hash"]
    ipmi_default    = masterdefaults["ipmi_hash"]

    if (poddefaults != nil and poddefaults["private_hash"] != nil) then
      private_default.merge!(poddefaults["private_hash"])
    end
    if (poddefaults != nil and poddefaults["ipmi_hash"] != nil) then
      ipmi_default.merge!(poddefaults["ipmi_hash"])
    end

    pods.each_value { |val|
      val.merge!(poddefaults) 				{ | key, v1, v1 | v1 }
      val["private_hash"].merge!(private_default) 	{ | key, v1, v2 | v1 }
      val["ipmi_hash"].merge!(ipmi_default) 		{ | key, v1, v2 | v1 }
    }

    pods
  end
end
