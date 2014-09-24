# Class: vclmgmt::xcat_vlan
#
# This class defines xcat_network objects and related network interface definitions if a network is on a vlan
# 
# Parameters:
# [*master_if*]
#   - Interface on the management node which is connected to this network
# [*master_mac*]
#   - MAC Address of interface on the management node which is connected to this network
# [*master_ip*]
#   - IP Address of the management node (not its alias for this vlan, if you have multiple networks through this interface.  This is important to prevent your private network traffic from being intercepted by the firewall)
# [*vlan_alias_ip*] 
#   - IP Address of the management node on this network, if you have several networks on separate vlans through this interface
#     Defaults to undef
# [*domain*]
#   - Domain of this network
# [*network*]
#   - Network address
# [*netmask*]
#   - Network netmask
# [*broadcast*]
#   - Broadcast address for this network
# [*vlanid*] 
#   - Vlan ID, if you have multiple networks through this interface
#     Defaults to undef
define vclmgmt::xcat_vlan(
  $master_if, 
  $master_mac, 
  $master_ip, 
  $vlan_alias_ip  = undef, 
  $domain, 
  $network, 
  $netmask, 
  $broadcast,
  $vlanid         = undef
) {
  
  $default = {
    mgtifname   => $master_if,
    nameservers => $master_ip,
    dhcpserver  => $master_ip,
    tftpserver  => $master_ip,
    domain      => $domain,
    net         => $network,
    mask        => $netmask,
  }

  $subdef = {
    broadcast   => $broadcast,
    netmask     => $netmask,
    domain_name => $domain,
    other_opts  => ['filename "pxelinux.0"', "next-server ${master_ip}"],
    require     => Class['::dhcp::server'],
  }

  $xcatmask = split($netmask, '\.')

  if $vlan_alias_ip == undef {
    $xcatnet = split($master_ip, '\.')
    $nethash = {
      "${domain}" => {
        gateway     => $master_ip,
      },
      "${xcatnet[0]}_${xcatnet[1]}_${xcatnet[2]}_0-${xcatmask[0]}_${xcatmask[1]}_${xcatmask[2]}_${xcatmask[3]}" => {
        ensure => absent,
      }
    }

    $subnet = { 
      "${network}" => {
        routers => [ $master_ip, ],
      }
    }
  }
  else {
    $xcatnet = split($vlan_alias_ip, '\.')
    network::if::static { "${master_if}.${vlanid}" :
      ensure      => 'up',
      ipaddress   => $vlan_alias_ip,
      netmask     => $netmask,
      macaddress  => $master_mac,
      vlan        => true,
      domain      => $domain,
    }
    
    $subnet = { 
      "${network}" => {
        routers => [ $vlan_alias_ip, ],
      }
    }

    $nethash = {
      "${domain}" => {
        vlanid => $vlanid,
        gateway     => $vlan_alias_ip,
      },
      "${xcatnet[0]}_${xcatnet[1]}_${xcatnet[2]}_0-${xcatmask[0]}_${xcatmask[1]}_${xcatmask[2]}_${xcatmask[3]}" => {
        ensure => absent,
      }
    }
  }

  create_resources(xcat_network, $nethash, $default)
  create_resources(dhcp::subnet, $subnet, $subdef)

  Xcat_network <| ensure == absent |> -> Xcat_network <| ensure != absent |>

  bind::zone { $domain :
    zone_contact => 'netlabs@help.ncsu.edu',
    zone_ns      => $master_ip,
    zone_serial  => '2012112901',
    zone_ttl     => '604800',
    zone_origin  => $domain,
  }
}
