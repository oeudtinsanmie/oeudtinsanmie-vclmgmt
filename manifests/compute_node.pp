include vclmgmt

define vclmgmt::compute_node(
	$public_ip, 
	$public_mac,
	$private_ip, 
	$private_mac, 
	$private_if, 
	$xcat_groups	= [ 'ipmi', 'compute', 'all' ],
	$vcl_groups 	= [ 'allComputers' ],
	$tgt_os 		= 'Linux', 
	$tgt_arch 		= 'x86_64', 
	$ipmi_ip, 
	$ipmi_mac, 
	$ipmi_user, 
	$ipmi_pw, 
	$master_ip,
	$profile,
	$netboot 		= 'pxe',
	$provmethod 	= 'install'
	$ram 			= undef,
	$procnumber 	= undef,
    $procspeed 		= undef,
    $network		= undef,
    $type			= undef,
    $drivetype		= undef, 
    $deleted		= undef, 	    
    $notes			= undef,
    $location		= undef,
    $dsa			= undef,
    $dsapub			= undef,
    $rsa			= undef,
    $rsapub			= undef,
    $hostpub		= undef,
  	$state			= undef,
  	$platform		= undef,
  	$schedule		= undef,
  	$image			= undef,
  	$imagerevision	= undef,
  	$provisioning	= undef,
  	$vmhost			= undef,
  	$vmtype			= undef,
) {
	xcat_node { $name :
		groups 		=> $xcat_groups,
		ip			=> $private_ip,
		mac			=> $private_mac,
		bmc			=> "${name}-ipmi",
		bmcusername	=> $ipmi_user,
		bmcpassword	=> $ipmi_pw,
		mgt			=> "ipmi",
        installnic	=> "bootif",
		primarynic	=> $private_if,
		netboot		=> $netboot,
		os			=> $tgt_os,
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
	
	vcl_computer { $name :
		hostname 		=> $name,
		public_ip 		=> $public_ip,
		private_ip		=> $private_ip,
		public_ip 		=> $public_mac,
		private_ip		=> $private_mac,
		ram				=> $ram,
		procnumber		=> $procnumber,
        procspeed		=> $procspeed,
        network			=> $network,
        type 			=> $type,
        drivetype   	=> $drivetype,      
        deleted         => $deleted, 	    
        notes           => $notes, 	        
        location        => $location,       
        dsa             => $dsa,            
        dsapub          => $dsapub,         
        rsa             => $rsa,            
        rsapub          => $rsapub,         
        hostpub         => $hostpub,        
      	state           => $state, 		        
      	platform        => $platform,         
      	schedule        => $schedule,         
      	image           => $image,            
      	imagerevision	=> $imagerevision,    
      	provisioning    => $provisioning,     
      	vmhost        	=> $vmhost,
      	vmtype        	=> $vmtype,
	}
}
