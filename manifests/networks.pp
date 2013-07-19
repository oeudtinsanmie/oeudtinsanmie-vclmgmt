class vclmgmt::networks {
    network::if::static { 'image':
        interface => 'eth1',
        ensure => 'up',
        ipaddress => '172.20.0.1',
        netmask => '255.255.255.0',
        macaddress => $vclmgmt::params::image_mac,
        bootproto => 'static',
        require => Class['vclmgmt::params'],
    }
    network::if::static { 'ipmi':
        interface => 'eth2',
        ensure => 'up',
        ipaddress => '172.25.0.1',
        netmask => '255.255.255.0',
        macaddress => $vclmgmt::params::ipmi_mac,
        bootproto => 'static',
        require => Class['vclmgmt::params'],
    }
    network::if::dynamic { 'public':
        interface => 'eth0',
        ensure => 'up',
        netmask => '255.255.255.0',
        macaddress => $vclmgmt::params::public_mac,
        bootproto => 'dhcp',
        require => Class['vclmgmt::params'],
    }
}
