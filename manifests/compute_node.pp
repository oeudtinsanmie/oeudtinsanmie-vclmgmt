include vclmgmt

define vclmgmt::compute_node($node, $private_servname, $private_ip, $private_mac, $private_if, $ipmi_ip, $ipmi_mac, $ipmi_if, $ipmi_user, $ipmi_pw, $tgt_if, $tgt_os = 'Linux', $tgt_arch = 'x86_64', $slotid, $admin_user, $admin_pw) {
	xcat_node { $node 
		groups 		=> [ "compute", "all"],
		ip		=> $private_ip,
		mac		=> $private_mac,
		interface	=> $private_if,
		bmc		=> "${node}-ipmi",
		bmcusername	=> $ipmi_user,
		bmcpassword	=> $ipmi_pw,
		bmcport		=> 0,
		mgt		=> "ipmi",
		netboot		=> "pxe",
		tftpserver	=> $private_servname,
		nfsserver	=> $private_servname,
		nfsdir		=> "/install",
		installnic	=> $tgt_if,
		primarynic	=> $tft_if,
		xcatmaster	=> $private_servname,
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
		ip		=> $ipmi_ip,
		mac		=> $ipmi_mac,
		interface	=> $ipmi_if,
	}
}
