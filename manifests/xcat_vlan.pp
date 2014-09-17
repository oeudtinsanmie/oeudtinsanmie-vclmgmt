define vclmgmt::xcat_vlan(
	$master_if, 
	$master_mac, 
	$master_ip, 
	$vlan_alias_ip = undef, 
	$domain, 
	$network, 
	$netmask, 
	$broadcast,
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

    $subdef = {
        broadcast => $broadcast,
        netmask => $netmask,
        domain_name => $domain,
        other_opts => ['filename "pxelinux.0"', "next-server ${master_ip}"],
        require => Class['::dhcp::server'],
    }

    if $vlan_alias_ip == undef {
	$nethash = {
	    "${domain}" => {}
	}

        $subnet = { 
            "${network}" => {
                routers => [ $master_ip, ],
            }
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
        $subnet = { 
            "${network}" => {
                routers => [ $vlan_alias_ip, ],
            }
        }

	$nethash = {
		"${domain}" => {
			vlanid => $vlanid,
		}
	}

    }

    create_resources(xcat_network, $nethash, $default)
    create_resources(dhcp::subnet, $subnet, $subdef)

    bind::zone { $domain :
        zone_contact => 'netlabs@help.ncsu.edu',
        zone_ns      => $master_ip,
        zone_serial  => '2012112901',
        zone_ttl     => '604800',
        zone_origin  => $domain,
    }
}
