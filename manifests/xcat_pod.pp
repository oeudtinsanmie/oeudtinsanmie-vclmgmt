define vclmgmt::xcat_pod(
	$private_hash, 
	$ipmi_hash, 
	$defaults = undef, 
	$nodes
) {
	ensure_resource(vclmgmt::xcat_vlan, $name, $private_hash)
	ensure_resource(vclmgmt::xcat_vlan, "${name}-ipmi", $ipmi_hash)
	
#	if $private_hash[vlanid] == undef {
#		$private_if = $private_hash[master_if]
#	}
#	else {
#		$private_if = "${private_hash[master_if]}.${private_hash[vlanid]}"
#	}
#	
#	if $ipmi_hash[vlanid] == undef {
#		$ipmi_if = $ipmi_hash[master_if]
#	}
#	else {
#		$ipmi_if = "${ipmi_hash[master_if]}.${ipmi_hash[vlanid]}"
#	}


#	$tmphash = {
#		tgt_net 	=> $private_hash[network],
#                tgt_domain	=> $private_hash[domain],
#		ipmi_net 	=> $ipmi_hash[network],
#                ipmi_domain     => $ipmi_hash[domain],
#		master_if	=> $private_if,
#		master_ipmi_if	=> $ipmi_if,
#	}

#	if $defaults == undef {
#		$mydefaults = $tmphash
#	}
#	else {
#		$mydefaults = merge($tmphash, $defaults)
#	}

#	create_resources(vclmgmt::compute_node, $nodes, $mydefaults)
	create_resources(vclmgmt::compute_node, $nodes, $defaults)
}
