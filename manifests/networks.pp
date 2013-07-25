class vclmgmt::networks {
    network::if::static { 'em2':
        ensure => 'up',
        ipaddress => '172.20.0.1',
     	netmask   => '255.255.255.0',
        macaddress => $vclmgmt::params::image_mac,
        require => Class['vclmgmt::params'],
    }
    network::if::static { 'p4p1':
        ensure => 'up',
        ipaddress => '172.25.0.1',
     	netmask   => '255.255.255.0',
        macaddress => $vclmgmt::params::ipmi_mac,
        require => Class['vclmgmt::params'],
    }
    network::if::dynamic { 'em1':
        ensure => 'up',
        macaddress => $vclmgmt::params::public_mac,
        bootproto => 'dhcp',
        require => Class['vclmgmt::params'],
    }
}
