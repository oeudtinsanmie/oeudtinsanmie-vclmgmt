include vclmgmt

define vclmgmt::compute_node($tgt_node, $tgt_ip, $tgt_mac, $tgt_if, $tgt_net, $tgt_os = 'Linux', $tgt_arch = 'x86_64', $slotid, $ipmi_ip, $ipmi_mac, $ipmi_net, $ipmi_user, $ipmi_pw, $master_if, $master_ipmi_if, $admin_user, $admin_pw) {
	xcat_node { $tgt_node :
		groups 		=> [ "compute", "all"],
		ip		=> $tgt_ip,
		mac		=> $tgt_mac,
		interface	=> $master_if,
		bmc		=> "${tgt_node}-ipmi",
		bmcusername	=> $ipmi_user,
		bmcpassword	=> $ipmi_pw,
		bmcport		=> 0,
		mgt		=> "ipmi",
		netboot		=> "pxe",
		tftpserver	=> $master_ip,
		nfsserver	=> $master_ip,
		nfsdir		=> "/install",
		installnic	=> $tgt_if,
		primarynic	=> $tft_if,
		xcatmaster	=> $master_ip,
		os		=> $tgt_os,
		arch		=> $tgt_arch,
		provmethod	=> "install",
		mpa		=> "${tgt_node}-ipmi",
		slotid		=> $slotid,
	        domainadminuser => $admin_user,
        	domainadminpassword => $admin_pw,
	}
	
	xcat_node { "${tgt_node}-ipmi" :
		groups 		=> [ "ipmi", "all"],
                ip              => $ipmi_ip,
                mac             => $ipmi_mac,
                interface	=> $master_ipmi_if,
	}

	dhcp::hosts { $tgt_node :
	    	subnet => $tgt_net,
	    	'hash_data' => {
			$tgt_node => {
				'interfaces' => {
					$tgt_if => $tgt_mac,
				},
			},
		},
	}

	dhcp::hosts { "${tgt_node}-ipmi" :
	    	subnet => $ipmi_net,
	    	'hash_data' => {
			"${tgt_node}-ipmi" => {
				'interfaces' => {
					$ipmi_if => $ipmi_mac,
				},
			},
		},
	}
}
