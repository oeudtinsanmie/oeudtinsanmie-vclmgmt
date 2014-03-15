include vclmgmt

define vclmgmt::compute_node($node, $tgt_ip, $tgt_mac, $tgt_if, $tgt_os = 'Linux', $tgt_arch = 'x86_64', $slotid, $ipmi_ip, $ipmi_mac, $ipmi_user, $ipmi_pw, $master_if, $master_ipmi_if, $admin_user, $admin_pw) {
	xcat_node { $node 
		groups 		=> [ "compute", "all"],
		ip		=> $tgt_ip,
		mac		=> $tgt_mac,
		interface	=> $master_if,
		bmc		=> "${node}-ipmi",
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
		mpa		=> "${node}-ipmi",
		slotid		=> $slotid,
	        domainadminuser => $admin_user,
        	domainadminpassword => $admin_pw,
	}
	
	xcat_node { "${node}-ipmi" :
		groups 		=> [ "ipmi", "all"],
                ip              => $ipmi_ip,
                mac             => $ipmi_mac,
                interface	=> $master_ipmi_if,
	}
}
