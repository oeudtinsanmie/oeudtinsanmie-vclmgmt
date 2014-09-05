include vclmgmt

define vclmgmt::compute_node(
	$tgt_ip, 
	$tgt_mac, 
	$tgt_if, 
	$groups = [ "ipmi", "compute", "all" ],

#	$tgt_net, 
#	$tgt_domain,

	$tgt_os = 'Linux', 
	$tgt_arch = 'x86_64', 
	$ipmi_ip, 
	$ipmi_mac, 

#	$ipmi_net, 
#	$ipmi_domain,

	$ipmi_user, 
	$ipmi_pw, 
	$master_ip,

#	$master_if, 
#	$master_ipmi_if, 

##	$admin_user, 
##	$admin_pw,

	$profile,
	$netboot = 'pxe',
	$provmethod = 'install'
) {
	xcat_node { $name :
		groups 		=> $groups,
		ip		=> $tgt_ip,
		mac		=> $tgt_mac,
		bmc		=>  "${name}-ipmi",
		bmcusername	=> $ipmi_user,
		bmcpassword	=> $ipmi_pw,
		mgt		=> "ipmi",
                installnic	=> "bootif",
		primarynic	=> $tgt_if,
		netboot		=> $netboot,
		os		=> $tgt_os,
		profile		=> $profile,
		provmethod	=> $provmethod,
		xcatmaster	=> $master_ip,
		nfsserver	=> $master_ip,
	}
	
	xcat_node {  "${name}-ipmi" :
		groups 		=> [ "all" ],
                ip              => $ipmi_ip,
                mac             => $ipmi_mac,
	}

#	dhcp::hosts { $name:
# 		subnet    => $tgt_net,
#   		hash_data => {
#     			"${name}.${tgt_domain}" => {
#       				interfaces => {
#         				"${master_if}" => $tgt_mac,
#       				}
#     			}
#   		}
#	}
#        
#        dhcp::hosts { "${name}-ipmi":
#                subnet    => $ipmi_net,
#                hash_data => {
#                 	"${name}-ipmi.${ipmi_domain}" => {
#                                interfaces => {
#                                        "${master_ipmi_if}" => $ipmi_mac,
#                                }
#                 	}
#                }
#   	}

	
        
#        bind::a { $name:
#		ensure => present,
#		zone => $tgt_domain,
#		ptr => false,
#		hash_data => {
#			"${name}" => { owner => $tgt_ip, },
#		}
#   	}
                
#        bind::a { "${name}-ipmi":
#                ensure => present,
#                zone =>	$ipmi_domain,
#                ptr => false,
#                hash_data => {
#                        "${name}-ipmi" => { owner => $ipmi_ip, },
#         	}
#        }
}
