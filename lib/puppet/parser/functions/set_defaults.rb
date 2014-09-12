module Puppet::Parser::Functions
  newfunction(:set_defaults, :type => :rvalue) do |args|
    pods 		= args[0]
    poddefaults 	= args[1]
    masterdefaults 	= args[2]

    Puppet.debug "Parsing defaults for vclmgmt node" 
    private_default = { 
	"master_if" => masterdefaults["private_if"], 
	"master_ip" => masterdefaults["private_ip"], 
	"master_mac" => masterdefaults["private_mac"] 
    }
    ipmi_default    = { 
	"master_if" => masterdefaults["ipmi_if"], 
	"master_ip" => masterdefaults["ipmi_ip"], 
	"master_mac" => masterdefaults["ipmi_mac"] 
    }

    Puppet.debug "boo"
    if (poddefaults != nil and poddefaults["private_hash"] != nil) then
      private_default.merge!(poddefaults["private_hash"])
    end
    if (poddefaults != nil and poddefaults["ipmi_hash"] != nil) then
      ipmi_default.merge!(poddefaults["ipmi_hash"])
    end

    pods.each_value { |val|
      val["private_hash"].merge!(private_default) 	{ | key, v1, v2 | v1 }
      val["ipmi_hash"].merge!(ipmi_default) 		{ | key, v1, v2 | v1 }
      val.merge!(poddefaults) 				{ | key, v1, v2 | v1 }
    }

    Puppet.debug "done"
    pods
  end
end
