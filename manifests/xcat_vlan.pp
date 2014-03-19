include vclmgmt

define vclmgmt::xcat_vlan($master_if, $master_mac, $master_ip, $vlan_alias_ip, $domain, $network, $netmask, $ip_range, $vlanid) {
	
    network::if::static { "${master_if}.${vlanid}" :
	ensure 		=> 'up',
	ipaddress 	=> $vlan_alias_ip,
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
