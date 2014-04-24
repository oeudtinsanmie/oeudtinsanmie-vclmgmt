include vclmgmt

define vclmgmt::xcat_vlan(
	$master_if, 
	$master_mac, 
	$master_ip, 
	$vlan_alias_ip = undef, 
	$domain, 
	$network, 
	$broadcast, 
	$netmask, 
	$ip_range, 
	$vlanid
) {

    if $vlan_alias_ip == undef {
        $myvlan_alias_ip = $master_ip

	xcat_network { $domain :
		mgtifname => $master_if,
		nameservers => $master_ip,
		dhcpserver => $master_ip,
		tftpserver => $master_ip,
		domain => $domain,
		net => $network,
		mask => $netmask,
		dynamicrange => $ip_range,
	}
    }
    else { 
        $myvlan_alias_ip = $vlan_alias_ip

	network::if::static { "${master_if}.${vlanid}" :
		ensure 		=> 'up',
		ipaddress 	=> $myvlan_alias_ip,
		netmask 	=> $netmask,
		macaddress 	=> $master_mac,
		vlan 		=> true,
		domain 		=> $domain,
	}

	xcat_network { $domain :
		mgtifname => $master_if,
		nameservers => $master_ip,
		dhcpserver => $master_ip,
		tftpserver => $master_ip,
		domain => $domain,
		net => $network,
		mask => $netmask,
		dynamicrange => $ip_range,
		vlanid => $vlanid,
	}
    }
    notify {"Making dchp subnet: ${network} / ${netmask} -- ${domain}":}
    dhcp::subnet { $network :
	broadcast => $broadcast,
	routers => [ $myvlan_alias_ip, ],
	netmask => $netmask,
	domain_name => $domain,
	other_opts => ['filename "pxelinux.0"', "next-server ${myvlan_alias_ip}"],
	require => Class['::dhcp::server'],
    }

    bind::zone { $domain :
	zone_contact => 'netlabs@help.ncsu.edu',
  	zone_ns      => $master_ip,
  	zone_serial  => '2012112901',
  	zone_ttl     => '604800',
  	zone_origin  => $domain,
    }
}
