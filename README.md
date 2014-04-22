


vclmgmt
========================================================================================
creates a vclmgmt::mgmt_node type

      vclmgmt::mgmt_node { "mgmt_node" :
            vcldb       => 'vcl',                 # default value
            vcluser     => 'vcluser@localhost',   # default value
            vcluser_pw	=> PASSWORD,              # vcl user password
            root_pw	    => ANOTHER_PASSWORD,  # root user password for mysql
            
            public_if   => 'em1',                 # default value
            public_mac  => XX:XX:XX:XX:XX:XX,     # MAC address for public network interface
            public_ip   => 'dhcp',                # default value
            private_if  => 'em2',                 # default value
            private_mac => XX:XX:XX:XX:XX:XX,     # MAC address for public network interface
            private_ip  => '172.20.0.1',          # default value
            ipmi_if     => 'p4p1',                # default value
            ipmi_mac    => XX:XX:XX:XX:XX:XX,     # MAC address for public network interface
            ipmi_ip     => '172.25.0.1',          # default value
      }
