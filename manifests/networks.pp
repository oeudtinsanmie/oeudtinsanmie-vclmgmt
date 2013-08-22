define vclmgmt::networks($public_mac, $public_if, $public_ip, $private_mac, $private_ip, $private_if, $ipmi_mac, $ipmi_ip, $ipmi_if) {
	network::if::static { $private_if :
		ensure => 'up',
		ipaddress => $private_ip,
		netmask   => '255.255.255.0',
		macaddress => $private_mac,
		require => Class['vclmgmt::params'],
	}
	network::if::static { $ipmi_if :
		ensure => 'up',
		ipaddress => $ipmi_ip,
		netmask   => '255.255.255.0',
		macaddress => $ipmi_mac,
		require => Class['vclmgmt::params'],
	}

	if $public_ip == 'dhcp' {
		network::if::dynamic { $public_if :
			ensure => 'up',
			macaddress => $public_mac,
			bootproto => 'dhcp',
#			peerdns	=> 'no',
			require => Class['vclmgmt::params'],
		}
	}
	else {
		network::if::static { $public_if :
			ensure => 'up',
			ipaddress => $public_ip,
			netmask   => '255.255.255.0',
			macaddress => $public_mac,
			require => Class['vclmgmt::params'],
		}
	}
}
