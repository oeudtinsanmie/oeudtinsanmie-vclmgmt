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
#   - Hash of vclmgmt::compute_nodes to declare with this network pair's settings
#     Defaults to undef
# [*usexcat*]
#   - Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers
#     Defaults to false
#
define vclmgmt::xcat_pod(
  $ensure = present,
  $private_hash, 
  $ipmi_hash = undef, 
  $defaults = undef, 
  $nodes = undef,
  $usexcat = false,
) {
  if $private_hash == undef or ($private_hash["ovs_bridge"] == undef and $private_hash['master_if'] == undef) {
    fail "vclmgmt::xcat_pod ${name} requires \$master_if to be defined in \$private_hash"
  }
  if $private_hash['master_ip'] == undef {
    fail "vclmgmt::xcat_pod ${name} requires \$master_ip to be defined in \$private_hash"
  }
  if $private_hash['master_mac'] == undef {
    fail "vclmgmt::xcat_pod ${name} requires \$master_mac to be defined in \$private_hash"
  }
  ensure_resource(vclmgmt::xcat_vlan, $name, merge($private_hash, { usexcat => $usexcat, ensure => $ensure, }) )
  if $ipmi_hash != undef and $ipmi_hash['master_if'] != undef {
    if $ipmi_hash['master_ip'] == undef {
      fail "vclmgmt::xcat_pod ${name} requires \$master_ip to be defined in \$ipmi_hash"
    }
    if $ipmi_hash['master_mac'] == undef {
      fail "vclmgmt::xcat_pod ${name} requires \$master_mac to be defined in \$ipmi_hash"
    }
    ensure_resource(vclmgmt::xcat_vlan, "${name}-ipmi", merge($ipmi_hash, { usexcat => $usexcat, ensure => $ensure, }) )
  }

  $tmphash = {
    master_ip => $private_hash[master_ip],
    usexcat => $usexcat,
    ensure => $ensure,
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
