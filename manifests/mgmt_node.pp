include vclmgmt

define vclmgmt::mgmt_node($public_mac, $public_if = 'em1', $public_ip = 'dhcp', $private_mac, $private_ip = '172.20.0.1', $private_if = 'em2', $ipmi_mac, $ipmi_ip = '172.25.0.1', $ipmi_if = 'p4p1', $vcldb = 'vcl', $vcluser = 'vcluser@localhost', $root_pw, $vcluser_pw, $vclhost = 'localhost', $serverip = 'localhost', $xmlrpc_pw = 'just_another_password', $xml_url = 'localhost', $ipmi_user, $ipmi_pw, $admin_user, $adimin_pw) {
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

        vclmgmt::xcat_init { “init_xcat” :
                ipmi_ip		=> $ipmi_ip,
                ipmi_user	=> $ipmi_user,
                ipmi_pw		=> $ipmi_pw,
                admin_user	=> $admin_user,
                admin_pw	=> $admin_pw,
        }
}
