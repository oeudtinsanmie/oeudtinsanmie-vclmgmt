include vclmgmt

define vclmgmt::xcat_pod($private_hash, $ipmi_hash, $defaults = undef, $nodes) {
	ensure_resource(vclmgmt::xcat_vlan, $name, $private_hash)
	ensure_resource(vclmgmt::xcat_vlan, "${name}-ipmi", $ipmi_hash)
	
	$tmphash = {
		tgt_net 	=> $private_hash[network],
		ipmi_net 	=> $ipmi_hash[network],
		master_if	=> $private_hash[master_if],
		master_ipmi_if	=> $ipmi_hash[master_if],
	}

	if $defaults == undef {
		$defaults = $tmphash
	}
	else {
		$defaults = merge($tmphash, $defaults)
	}

	if $private_hash[vlanid] != undef {
		$tmphash = { 
		master_if	=> "${private_hash[master_if]}.${private_hash[vlanid]}", 
		}
		$defaults = merge($tmphash, $defaults)
	}

	if $ipmi_hash[vlanid] != undef {
		$tmphash = { 
		master_ipmi_if	=> "${ipmi_hash[master_if]}.${ipmi_hash[vlanid]}", 
		}
		$defaults = merge($tmphash, $defaults)
	} 

	create_reasources(vclmgmt::compute_node, $nodes, $defaults)
}
