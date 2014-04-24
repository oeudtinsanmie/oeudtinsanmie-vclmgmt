module Puppet::Parser::Functions
  newfunction(:set_defaults, :type => :rvalue) do |args|
    pods 	= args[0]
    private_if 	= args[1]
    private_ip 	= args[2]
    private_mac = args[3]

    ipmi_if 	= args[4]
    ipmi_ip 	= args[5]
    ipmi_mac 	= args[6]

    private_default = Hash[ "master_if" => private_if, "master_ip" => private_ip, "master_mac" => private_mac ]
    ipmi_default = Hash[ "master_if" => ipmi_if, "master_ip" => ipmi_ip, "master_mac" => ipmi_mac ]

    pods.each_value { |val|
      val["private_hash"].merge!(private_default) { |key, v1, v2| v1 }
      val["ipmi_hash"].merge!(ipmi_default) { |key, v1, v2| v1 }
    }

    pods
  end
end
