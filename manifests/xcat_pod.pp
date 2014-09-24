# Class: vclmgmt::xcat_pod
#
# This class defines related xcat_network objects for a private / ipmi network pair within xCAT
# If node hashes are provided, they are populated with sane defaults from the network definitions
# Precedence follows node definition > defaults hash definition > network definition
#
# Parameters:
# [*private_hash*]
#   - An xcat_vlan hash for the private network
# [*ipmi_hash*]
#   - An xcat_vlan hash for the ipmi network
# [*defaults*] 
#   - Default values for node definitions within the nodes hash, if defined
#     Defaults to undef
# [*nodes*] 
#   - Nodes to declare with this network pair's settings
#     Defaults to undef
#
define vclmgmt::xcat_pod(
  $private_hash, 
  $ipmi_hash, 
  $defaults = undef, 
  $nodes = undef,
) {
  ensure_resource(vclmgmt::xcat_vlan, $name, $private_hash)
  ensure_resource(vclmgmt::xcat_vlan, "${name}-ipmi", $ipmi_hash)

  if $private_hash[vlanid] == undef {
    $private_if = $private_hash[master_if]
  }
  else {
    $private_if = "${private_hash[master_if]}.${private_hash[vlanid]}"
  }

  if $ipmi_hash[vlanid] == undef {
    $ipmi_if = $ipmi_hash[master_if]
  }
  else {
    $ipmi_if = "${ipmi_hash[master_if]}.${ipmi_hash[vlanid]}"
  }

  $tmphash = {
    master_ip    => $private_hash[master_ip],
    private_net    => $private_hash[network],
    private_domain    => $private_hash[domain],
    ipmi_net    => $ipmi_hash[network],
    ipmi_domain    => $ipmi_hash[domain],
    master_private_if   => $private_if,
    master_ipmi_if    => $ipmi_if,
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
