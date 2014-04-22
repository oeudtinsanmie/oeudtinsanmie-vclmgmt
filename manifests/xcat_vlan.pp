include vclmgmt

define vclmgmt::xcat_vlan($master_if, $master_mac, $master_ip, $vlan_alias_ip = undef, $domain, $network, $broadcast, $netmask, $ip_range, $vlanid) {

    if $vlan_alias_ip == undef {
        $vlan_alias_ip = $master_ip
    }

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

    dhcp::subnet { $network: 
	broadcast => $broadcast,
	domain_name => $domain,
	netmask => $netmask,
	other_opts => ['filename "pxelinux.0";', "next-server ${master_ip};",],
    }
}
