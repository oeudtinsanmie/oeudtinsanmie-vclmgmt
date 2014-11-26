# Class: vclmgmt::vlan
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
# [*vlanid*] 
#   - Vlan ID, if you have multiple networks through this interface
#     Defaults to undef
# [*usexcat*]
#   - Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers
#     Defaults to false
#
define vclmgmt::vlan(
  $ensure = present,
  $master_if, 
  $master_ifgroup = undef,
  $master_mac, 
  $master_ip, 
  $vlan_alias_ip  = undef, 
  $domain, 
  $network, 
  $netmask, 
  $vlanid         = undef,
  $usexcat        = false,
  $ovs_bridge     = undef,
) {
  $default = {
    ensure      => $ensure,
    nameservers => $master_ip,
    dhcpserver  => $master_ip,
    tftpserver  => $master_ip,
    domain      => $domain,
    net         => $network,
    mask        => $netmask,
  }
  $xcatmask = split($netmask, '\.')

  if $vlan_alias_ip == undef {
    $xcatnet = split($master_ip, '\.')
    
    if $ovs_bridge != undef {
      $mgtifname = "${ovs_bridge}if"
      $add_interface = "${ovs_bridge}if"
    }
    else {
      $mgtifname = $master_if
      $add_interface = $master_if
    }
    $gateway = $master_ip
  }
  else {
    $xcatnet = split($vlan_alias_ip, '\.')
    
    if $ovs_bridge != undef {
      $mgtifname = "${ovs_bridge}if"
      
      Vs_bridge <| title == $ovs_bridge |> {
        vlans +> $vlanid,
      } 
      vs_port { "${ovs_bridge}if.${vlanid}":
        tag => $vlanid,
      }
      $add_interface = "${ovs_bridge}if.${vlanid}"

      if $master_if != undef {
        if $master_ifgroup != undef {
	        if defined(Vs_port[$master_ifgroup]) {
	          Vs_port <| title == $master_ifgroup |> {
	            trunks +> $vlanid,
	          }
	        }
	        else {
	          vs_port { $master_ifgroup :
	            interfaces => $master_if,
	            trunks => [ $vlanid, ]
	          }
	        }          
        }
        else {
          if defined(Vs_port["br_${master_if}"]) {
            Vs_port <| title == "br_${master_if}" |> {
              trunks +> $vlanid,
            }
          }
          else {
            vs_port { "br_${master_if}" :
              interfaces => $master_if,
              trunks => [ $vlanid, ],
            }
          } 
        }
      }
    }
    else {
      $mgtifname = $master_if
      
	    network::if::static { "${master_if}.${vlanid}" :
	      ensure      => 'up',
	      ipaddress   => $vlan_alias_ip,
	      netmask     => $netmask,
	      macaddress  => $master_mac,
	      vlan        => true,
	      domain      => $domain,
	    }
	    $add_interface = "${master_if}.${vlanid}"
    }
    
    $gateway = $vlan_alias_ip 
  }     
  $nethash = {
    "${domain}" => {
      mgtifname   => $mgtifname,
      vlanid      => $vlanid,
      gateway     => $gateway,
    },
    "${xcatnet[0]}_${xcatnet[1]}_${xcatnet[2]}_0-${xcatmask[0]}_${xcatmask[1]}_${xcatmask[2]}_${xcatmask[3]}" => {
      ensure => absent,
    }
  }

  if $usexcat == true {
	  create_resources(xcat_network, $nethash, $default)
	  
    Xcat_site_attribute <| title == 'dhcpinterfaces' |> {
      value +> $add_interface,
    }       
  }
}
