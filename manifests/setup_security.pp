class vclmgmt::setup_security {
    
    Firewall {
        require => Class['ncsufirewall::pre'],
	before  => Class['ncsufirewall::post'],
    }

    firewall { '100 accept http':
        chain => 'INPUT',
        proto => 'tcp',
        action=> 'accept',
        dport => 80,
        state => 'NEW',
    }
    firewall { '105 accept https':
        chain => 'INPUT',
        proto => 'tcp',
        action=> 'accept',
        dport => 443,
        state => 'NEW',
    }
    firewall { '112 reject foward across vlans' :
	chain => 'FORWARD',
	proto => 'all',
	action => 'reject',
    }
# SELinux not installed
#    selboolean { 'httpd can connect':
#        name => 'httpd_can_network_connect',
#        persistent => true,
#        value => 'on',
#    }
}
