define vclmgmt::xcat_vlan(
	$master_if, 
	$master_mac, 
	$master_ip, 
	$vlan_alias_ip = undef, 
	$domain, 
	$network, 
	$netmask, 
	$vlanid = undef
) {
    $default = {
    	mgtifname => $master_if,
        nameservers => $master_ip,
        dhcpserver => $master_ip,
        tftpserver => $master_ip,
        domain => $domain,
        net => $network,
        mask => $netmask,
    }

    if $vlan_alias_ip == undef {
	$nethash = {
		"${domain}" => {}
	}
    }
    else {

	network::if::static { "${master_if}.${vlanid}" :
		ensure 		=> 'up',
		ipaddress 	=> $vlan_alias_ip,
		netmask 	=> $netmask,
		macaddress 	=> $master_mac,
		vlan 		=> true,
		domain 		=> $domain,
	}

	$nethash = {
		"${domain}" => {
			vlanid => $vlanid,
		}
	}

    }

    create_resources(xcat_network, $nethash, $default)

}
