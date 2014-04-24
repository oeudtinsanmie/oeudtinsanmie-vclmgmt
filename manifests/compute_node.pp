include vclmgmt

define vclmgmt::compute_node(
	$tgt_ip, 
	$tgt_mac, 
	$tgt_if, 
	$tgt_net, 
	$tgt_domain,
	$tgt_os = 'Linux', 
	$tgt_arch = 'x86_64', 
	$slotid, 
	$ipmi_ip, 
	$ipmi_mac, 
	$ipmi_net, 
	$ipmi_domain,
	$ipmi_user, 
	$ipmi_pw, 
	$master_if, 
	$master_ipmi_if, 
	$admin_user, 
	$admin_pw
) {
	xcat_node { $name :
		groups 		=> [ "compute", "all"],
		ip		=> $tgt_ip,
		mac		=> $tgt_mac,
		interface	=> $master_if,
		bmc		=> "${name}-ipmi",
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
		mpa		=> "${name}-ipmi",
		slotid		=> $slotid,
	        domainadminuser => $admin_user,
        	domainadminpassword => $admin_pw,
	}
	
	xcat_node { "${name}-ipmi" :
		groups 		=> [ "ipmi", "all"],
                ip              => $ipmi_ip,
                mac             => $ipmi_mac,
                interface	=> $master_ipmi_if,
	}

	dhcp::hosts { $name:
 		subnet    => $tgt_net,
   		hash_data => {
     			"${name}" => {
       				interfaces => {
         				"${master_if}" => $tgt_mac,
       				}
     			}
   		}
	}
        
        dhcp::hosts { "${name}-ipmi":
                subnet    => $ipmi_net,
                hash_data => {
                 	"${name}-ipmi" => {
                                interfaces => {
                                        "${master_if}" => $ipmi_mac,
                                }
                 	}
                }
   	}

	
        
        bind::a { $name:
		ensure => present,
		zone => $tgt_domain,
		ptr => false,
		hash_data => {
			"${name}" => { owner => $tgt_ip, },
		}
   	}
                
        bind::a { "${name}-ipmi":
                ensure => present,
                zone =>	$ipmi_domain,
                ptr => false,
                hash_data => {
                        "${name}-ipmi" => { owner => $ipmi_ip, },
         	}
        }
}
