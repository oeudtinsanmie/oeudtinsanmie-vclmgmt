include vclmgmt

define vclmgmt::compute_node(
        $ensure		= present,
	$hostname	= $title,
	$public_ip, 
	$public_mac,
	$private_ip, 
	$private_mac, 
	$private_if, 
        $private_net,
        $private_domain,
	$xcat_groups	= [ 'ipmi', 'compute', 'all' ],
	$vcl_groups 	= [ 'allComputers' ],
	$tgt_os, 
	$tgt_arch	= undef,
	$ipmi_ip, 
	$ipmi_mac, 
        $ipmi_net,
        $ipmi_domain,
	$ipmi_user, 
	$ipmi_pw, 
	$master_ip,
        $master_private_if,
        $master_ipmi_if,
	$profile,
	$username	= 'root',
	$password,
	$netboot	= 'pxe',
	$provmethod	= 'install',
	$ram		= undef,
	$procnumber	= undef,
    	$procspeed	= undef,
    	$network	= undef,
    	$type		= undef,
    	$drivetype	= undef, 
    	$deleted	= undef, 	    
    	$notes		= undef,
    	$location	= undef,
    	$dsa		= undef,
    	$dsapub		= undef,
    	$rsa		= undef,
    	$rsapub		= undef,
    	$hostpub	= undef,
  	$state		= undef,
  	$platform	= undef,
  	$vclschedule	= undef,
  	$image		= undef,
  	$imagerevision	= undef,
  	$provisioning	= undef,
  	$vmhost		= undef,
  	$vmtype		= undef,
) {
	xcat_node { $hostname :
		ensure			=> $ensure,
		groups			=> $xcat_groups,
		ip			=> $private_ip,
		mac			=> $private_mac,
		bmc			=> "${hostname}-ipmi",
		bmcusername		=> $ipmi_user,
		bmcpassword		=> $ipmi_pw,
		mgt			=> "ipmi",
        	installnic		=> 'bootif',
		primarynic		=> $private_if,
		netboot			=> $netboot,
		os			=> $tgt_os,
		arch			=> $tgt_arch,
		profile			=> $profile,
		provmethod		=> $provmethod,
		xcatmaster		=> $master_ip,
		nfsserver		=> $master_ip,
		domainadminuser		=> $username,
		domainadminpassword 	=> $password,
	}
	
	xcat_node {  "${hostname}-ipmi" :
		ensure		=> $ensure,
		groups		=> [ "all" ],
                ip		=> $ipmi_ip,
                mac		=> $ipmi_mac,
	}

	dhcp::hosts { $hostname:
                subnet    => $private_net,
                hash_data => {
                        "${hostname}.${private_domain}" => {
                                interfaces => {
                                        "${master_private_if}" => $private_mac,
                                }
                        }
                }
        }

	dhcp::hosts { "${hostname}-ipmi":
                subnet    => $ipmi_net,
                hash_data => {
                        "${hostname}-ipmi.${ipmi_domain}" => {
                                interfaces => {
                                        "${master_ipmi_if}" => $ipmi_mac,
                                }
                        }
                }
        }



	bind::a { $hostname:
                ensure => present,
                zone => $private_domain,
                ptr => false,
                hash_data => {
                        "${hostname}" => { owner => $private_ip, },
                }
        }

	bind::a { "${hostname}-ipmi":
                ensure => present,
                zone => $ipmi_domain,
                ptr => false,
                hash_data => {
                        "${hostname}-ipmi" => { owner => $ipmi_ip, },
                }
        }
	
	vcl_computer { $hostname :
		ensure		=> $ensure,
		hostname	=> $hostname,
		public_ip	=> $public_ip,
		private_ip	=> $private_ip,
		public_mac 	=> $public_mac,
		private_mac	=> $private_mac,
		ram		=> $ram,
		procnumber	=> $procnumber,
        	procspeed	=> $procspeed,
        	network		=> $network,
        	type		=> $type,
        	drivetype   	=> $drivetype,      
        	deleted		=> $deleted, 	    
        	notes		=> $notes, 	        
        	location	=> $location,       
        	dsa		=> $dsa,            
        	dsapub		=> $dsapub,         
        	rsa		=> $rsa,            
        	rsapub		=> $rsapub,         
        	hostpub		=> $hostpub,        
      		state		=> $state, 		        
      		platform	=> $platform,         
      		vclschedule	=> $vclschedule,         
      		image		=> $image,            
      		imagerevision	=> $imagerevision,    
      		provisioning	=> $provisioning,     
      		vmhost		=> $vmhost,
      		vmtype		=> $vmtype,
	}
}
