vclmgmt
========================================================================================
Including the vclmgmt class installs XCAT and VCL, and creates these three types to allow you to configure your installation.

      include vclmgmt

vclmgmt::mgmt_node type configures the management node.  You can also include an array of hashes describing the vclmgmt::xcat_pod configurations for client subnets.  Pod configurations will inherit the private and impi mac addreses and interface names, by default.  Explicit definitions within the pods hash will override those defaults.

      vclmgmt::mgmt_node { "mgmt_node" :
            vcldb          => 'vcl',                 # default value
            vcluser        => 'vcluser@localhost',   # vcl mysql user
            vcluser_pw     => 'PASSWORD',            # vcl mysql user password
            root_pw        => 'ANOTHER_PASSWORD',    # root user password for mysql
            
            # public network parameters
            public_if      => 'em1',                 # default value
            public_mac     => 'XX:XX:XX:XX:XX:XX',   # MAC address for public network interface
            public_ip      => 'dhcp',                # default value
            
            # private network parameters
            private_if     => 'em2',                 # default value
            private_mac    => 'XX:XX:XX:XX:XX:XX',   # MAC address for public network interface
            private_ip     => '172.20.0.1',          # default value
            private_domain => 'mydomain',            # the domain name for your private network
            
            # ipmi network parameters
            ipmi_if        => 'p4p1',                # default value
            ipmi_mac       => 'XX:XX:XX:XX:XX:XX',   # MAC address for public network interface
            ipmi_ip        => '172.25.0.1',          # default value
            
            pods           => undef,                 # default value
      }

vclmgmt::xcat_pod describes the private and ipmi subnets for a given collection of compute nodes.  It accepts hashes defining the xcat_vlan objects for its private and ipmi subnets, as well as a defaults hash, which may be used to contain any values shared by both definitions.  In addition, you may include a hash describing the compute_node objects of this pod.  Compute nodes within this list will be passed definitions from the pod within their defaults hash, describing the private and ipmi interfaces, networks and domains.  These will be overridden by any explicit definition in the compute_node hashes.

      vclmgmt::xcat_pod { "pod7a" : 
            private_hash => { 
                vlan_alias_ip => '192.168.37.1',
                network       => '192.168.37.0',
                netmask       => '255.255.255.192',
                broadcast     => '192.168.37.63',
                domain        => 'mydomain',
                ip_range      => '192.168.37.4-192.168.37.63',
                vlanid        => '307',
            },
            ipmi_hash => {
                network       => '192.168.137.0',
                netmask       => '255.255.255.192',
                broadcast     => '192.168.137.63',
                domain        => 'ipmidomain',
                ip_range      => '192.168.137.4-192.168.137.63',
                vlanid        => '1307',
            },
            defaults => {
                tgt_if        => 'eth1',      # the interface of the target node, which is connected to the private network
                ipmi_user     => 'SOMEUSR',   # username of ipmi on target node
                ipmi_pw       => 'SOMEPASS',  # password for ipmi on target node
                admin_user    => 'adminuser', # username to create as administrator on target node
                admin_pw      => 'adminpass', # password for user on target node
            },
            nodes => {
                "my-node" => {
                    tgt_ip => "192.168.37.8",
                    ipmi_ip => "192.168.137.8",
                    tgt_mac => "XX:XX:XX:XX:XX:XX",
                    ipmi_mac => "XX:XX:XX:XX:XX:XX",
                    slotid => 1,
                },
            },
      }

vclmgmt::xcat_vlan configures dhcpd.conf and bind, and creates an xcat network object in xcat describing the network.  If vlan_alias_ip is not undefined, it will also create a network interface for the vlan.

      vclmgmt::xcat_vlan { "some_network" :
      	master_if     => 'eth0', 
            master_mac    => 'XX:XX:XX:XX:XX:XX',   # MAC address for network interface
      	master_ip     => '192.168.37.1',        # IP address for xcat management node on master_if
      	vlan_alias_ip => undef,                 # IP address for xcat management node on the subnet routed through this vlan, or undef if no vlan is used                 
      	domain        => 'mydomain',            # the domain name for this network
      	network       => '192.168.37.0'         # network root address  
      	broadcast     => '192.168.37.63',       # broadcast address for network
      	netmask       => '255.255.255.192',     # netmask for network
      	ip_range      => '192.168.37.4-192.168.37.63',   # ip range for dynamically allocated ip addresses in dhcpd.conf
      	vlanid        => undef,                 # vlan id, if defining a subnet isolated by a vlan on this interface.  Ignored if no vlan_alias_ip provided
      }

vclmgmt::compute_node adds an xcat node object describing the target node and configures the dhcp and dns settings for its private and ipmi network interfaces.

      vclmgmt::compute_node { "my-node" :
      	tgt_ip     => '192.168.37.8',        # IP address for target node on private network 
      	tgt_mac    => 'XX:XX:XX:XX:XX:XX',   # MAC address for private network interface 
      	tgt_if     => 'eth1',                # interface of target node connected to its private network 
      	tgt_net     => '192.168.37.0',       # private network for target node
      	tgt_domain  => 'mydomain',           # domain of private network for target node
      	tgt_os      => 'Linux',                # Operating system family for target node 
      	tgt_arch    => 'x86_64',               # Architecture of target node. 
      	slotid      => 1,                      # identifier for target node within its subnet.  Pick a unique integer. 
      	ipmi_ip     => '192.168.137.8',        # IP address for target node on ipmi network 
      	ipmi_mac    => 'XX:XX:XX:XX:XX:XX',    # MAC address for ipmi network interface 
      	ipmi_net     => '192.168.37.0',        # ipmi network for target node
      	ipmi_domain  => 'ipmidomain',          # domain of private network for target node
      	ipmi_user    => 'SOMEUSR',   # username of ipmi on target node 
      	ipmi_pw      => 'SOMEPASS',  # password for ipmi on target node 
      	master_if         => 'em2',                 # management node interface connected to this target node's private network 
      	master_ipmi_if    => 'p4p1',                # management node interface connected to this target node's ipmi network
      	admin_user   => 'adminuser', # username to create as administrator on target node 
      	admin_pw     => 'adminpass', # password for user on target node
      }

The nested hash structure and default-passing behavior of these puppet classes simplify defining a VCL installation in hiera, and then using the hiera_include, ensure_resource and create_resources functions. 

      ---
      classes:
          - vclmgmt
      
      mgmt_node:
          vcluser_pw: "vcl_sql_password"
          root_pw: "root_sql_password"
          ipmi_mac: "XX:XX:XX:XX:XX:XX"
          private_mac: "XX:XX:XX:XX:XX:XX"
          public_mac: "XX:XX:XX:XX:XX:XX"
          private_if: "em2"
          private_ip: "192.168.0.5"
          private_domain: "mydomain"
          ipmi_if: "p4p1"
          ipmi_ip: "192.168.100.5"
          pods:
              "my-pod":
                  private_hash:
                      vlan_alias_ip: "192.168.37.1"
                      network: "192.168.37.0"
                      netmask: "255.255.255.192"
                      broadcast: "192.168.37.63"
                      domain: "mypod.mydomain"
                      ip_range: "192.168.37.4-192.168.37.63"
                      vlanid: "307"
                  ipmi_hash:
                      network: "192.168.137.0"
                      netmask: "255.255.255.192"
                      broadcast: "192.168.137.63"
                      domain: "mypod-ipmi.mydomain"
                      ip_range: "192.168.137.4-192.168.137.63"
                      vlanid: "1307"
                  defaults:
                      tgt_if: "eth1"
                      ipmi_user: "SOMEUSER"
                      ipmi_pw: "SOMEPASS"
                      admin_user: "AdminUser"
                      admin_pw: "AdminPassword"
                  nodes:
                      "my-node":
                          tgt_ip: "192.168.37.8"
                          ipmi_ip: "192.168.137.8"
                          tgt_mac: "XX:XX:XX:XX:XX:XX"
                          ipmi_mac: "XX:XX:XX:XX:XX:XX"
                          slotid: 1
