define vclmgmt::xcat_pod(
	$private_hash, 
	$ipmi_hash, 
	$defaults = undef, 
	$nodes = undef,
) {
	ensure_resource(vclmgmt::xcat_vlan, $name, $private_hash)
	ensure_resource(vclmgmt::xcat_vlan, "${name}-ipmi", $ipmi_hash)

	$tmphash = {
		master_ip	=> $private_hash[master_ip],
		private_if
		private_net
		private_domain
		ipmi_if
		ipmi_net
		ipmi_domain
		master_private_if
		master_ipmi_if
	}

	if $defaults == undef {
		$mydefaults = $tmphash
	}
	else {
		$mydefaults = merge($tmphash, $defaults)
	}

	if $nodes != undef {
		create_resources(vclmgmt::compute_node, $nodes, $mydefaults)
	}
}
