class vclmgmt::setup_security {
    firewall { '100 accept http':
        chain => 'RH-Firewall-1-INPUT',
        proto => 'tcp',
        action=> 'accept',
        dport => 80,
        state_match => 'NEW',
    }
    firewall { '105 accept https':
        chain => 'RH-Firewall-1-INPUT',
        proto => 'tcp',
        action=> 'accept',
        dport => 443,
        state_match => 'NEW',
    }
    selboolean { 'httpd can connect':
        name => 'httpd_can_network_connect',
        persistent => true,
        value => 'on',
    }
}
