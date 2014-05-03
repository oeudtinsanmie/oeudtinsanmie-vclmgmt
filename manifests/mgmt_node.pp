include vclmgmt
include stdlib

define vclmgmt::mgmt_node(
	$public_mac, 
	$public_if = 'em1', 
	$public_ip = 'dhcp', 
	$private_mac, 
	$private_ip, 
	$private_if = 'em2', 
	$private_domain, 
	$ipmi_mac, 
	$ipmi_ip, 
	$ipmi_if = 'p4p1', 
	$vcldb = 'vcl', 
	$vcluser = 'vcluser', 
	$root_pw, 
	$vcluser_pw, 
	$vclhost = 'localhost', 
	$serverip = 'localhost', 
	$xmlrpc_pw = 'just_another_password', 
	$xml_url = 'localhost',
	$pods = undef
) {

	if $pods == undef {
		$dhcpinterfaces = [ $private_if, $ipmi_if ]
	}
	else {
		/* // Puppet 3 syntax:
		$dhcpinterfaces = $pods.map |$key, $val| { 
					[ 
					"${private_if}.${val[private_hash][vlanid]}", 
					"${ipmi_if}.${val[ipmi_hash][vlanid]}", 
					] 
				}
		$dhcpinterfaces = unique(flatten($dhcpinterfaces))
		if member($dhcpinterfaces, "${private_if}.") {
			$dhcpinterfaces = flatten( [ $private_if ], delete($dhcpinterfaces, "${private_if}."))
		}
		if member($dhcpinterfaces, "${ipmi_if}.") {
			$dhcpinterfaces = flatten( [ $ipmi_if ], delete($dhcpinterfaces, "${ipmi_if}."))
		}
		*/
		# defined a custom function to replace this for Puppet 2.7
		$dhcpinterfaces = list_vlans($pods, $private_if, $ipmi_if)
	}	

	vclmgmt::networks { "mgmt_interfaces" :
		public_mac 	=> $public_mac,
		public_if	=> $public_if, 
		public_ip	=> $public_ip, 
		private_mac	=> $private_mac, 
		private_ip	=> $private_ip, 
		private_if	=> $private_if, 
		ipmi_mac	=> $ipmi_mac, 
		ipmi_ip		=> $ipmi_ip, 
		ipmi_if		=> $ipmi_if, 
	}

    	firewall { '110 accept forward from me across bridges' :
        	chain => 'FORWARD',
        	proto => 'all',
        	action => 'accept',
		source => $private_ip,
    	}

    	firewall { "115 accept tftp" :
        	chain => 'INPUT',
        	proto => 'udp',
        	dport => 69,
        	action => 'accept',
        	destination => $private_ip,
    	}

        firewall { "116 accept sending tftp" :
                chain => 'INPUT',
                proto => 'udp',
                dport => 69,
                action => 'accept',
                source => $private_ip,
        }

	vclmgmt::sql_setup { "mgmt_sql" :
		vcldb		=> $vcldb, 
		vcluser		=> $vcluser, 
		root_pw		=> $root_pw, 
		vcluser_pw	=> $vcluser_pw,
	}
	
	vclmgmt::configure { "config_vcl_files" :
		vclhost		=> $vclhost,
		vcldb		=> $vcldb,
		vcluser		=> $vcluser,
		vcluser_pw	=> $vcluser_pw,
		serverip 	=> $serverip,
		xmlrpc_pw	=> $xmlrpc_pw,
		xml_url		=> $xml_url,
	}

        vclmgmt::xcat_init { "init_xcat" :
		ipmi_if		=> $ipmi_if,
                private_if	=> $private_if,
		dhcpinterfaces	=> $dhcpinterfaces,
		private_ip	=> $private_ip,
		private_domain 	=> $private_domain,
        }

	class { 'dhcp::server':
        #	opts => ['domain-name "toto.ltd"',
        #               'domain-name-servers 192.168.21.1'],                      
        }

	include bind

	if $pods != undef {
		/* // Puppet 3 syntax:
		$pods.each | $key, $val | {
			$val = merge($val, { 
				$private_hash => merge({
					master_if => $private_if,
					master_ip => $private_ip,
					master_mac => $private_mac,
				}, $val[private_hash]),
				$ipmi_hash => merge({
					master_if => $ipmi_if,
					master_ip => $ipmi_ip,
					master_mac => $ipmi_mac,
				}, $val[ipmi_hash]), 
			})
			ensure_resource(vclmgmt::xcat_pod, $key, $val)
		}
		*/
		# defined a custom function to replace this for Puppet 2.7
		$newpods = set_defaults($pods, $private_if, $private_ip, $private_mac, $ipmi_if, $ipmi_ip, $ipmi_mac)
		create_resources(vclmgmt::xcat_pod, $newpods)
	}
}
