module Puppet::Parser::Functions
  newfunction(:set_defaults, :type => :rvalue) do |args|
    pods            = args[0]
    poddefaults     = args[1]
    masterdefaults  = args[2]

    if (masterdefaults["usexcat"] != nil) then
      poddefaults["usexcat"] = masterdefaults["usexcat"]
    end
    private_default = { 
      "master_if"   => masterdefaults["private_if"], 
      "master_ip"   => masterdefaults["private_ip"], 
      "master_mac"  => masterdefaults["private_mac"] 
    }
    ipmi_default    = { 
      "master_if"   => masterdefaults["ipmi_if"], 
      "master_ip"   => masterdefaults["ipmi_ip"], 
      "master_mac"  => masterdefaults["ipmi_mac"] 
    }
    
    if masterdefaults["usevswitch"] == true then
      private_default["ovs_bridge"] = masterdefaults["privbridge"]
      ipmi_default["ovs_bridge"]    = masterdefaults["ipmibridge"]
      if masterdefaults["privategroup"] != nil then
        private_default["master_ifgroup"] = masterdefaults["privategroup"] 
      end
      if masterdefaults["ipmigroup"] != nil then
        ipmi_default["master_ifgroup"] = masterdefaults["ipmigroup"] 
      end
    end

    if (poddefaults != nil and poddefaults["private_hash"] != nil) then
      private_default.merge!(poddefaults["private_hash"])
    end
    if (poddefaults != nil and poddefaults["ipmi_hash"] != nil) then
      ipmi_default.merge!(poddefaults["ipmi_hash"])
    end

    pods.each_value { |val|
      val["private_hash"].merge!(private_default) { | key, v1, v2 | v1 }
      val["ipmi_hash"].merge!(ipmi_default)       { | key, v1, v2 | v1 }
      val.merge!(poddefaults)                     { | key, v1, v2 | v1 }
      if (val["defaults"] == nil) then
          val["defaults"] = {}
      end

      if (val["defaults"]["username"] == nil) then
          val["defaults"]["username"] = masterdefaults["system_user"]
      end 

      if (val["defaults"]["password"] == nil) then
          val["defaults"]["password"] = masterdefaults["system_pw"]
      end

    }

    pods
  end
end
