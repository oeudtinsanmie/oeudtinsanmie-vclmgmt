include vclmgmt

define vclmgmt::xcat_init($ipmi_ip, $ipmi_net, $ipmi_mask, $ipmi_range, $ipmi_if, $ipmi_domain, $ipmi_user, $ipmi_pw, $admin_user, $admin_pw, $private_net, $private_mask, $private_if, $private_range, $private_domain)  {

    xcat_site_attribute { "master" :
        sitename => 'clustersite',
        value => $fqdn,
    }

    xcat_site_attribute { "nameservers" :
        sitename => 'clustersite',
        value => $private_ip,
    }

    xcat_site_attribute { "dhcpinterfaces" :
	sitename => 'clustersite',
	value => [$private_if, $ipmi_if],
    }

    xcat_site_attribute { "domain" :
        sitename => 'clustersite',
        value => $private_domain,
    }

    xcat_site_attribute { "ntpservers" :
       	sitename => 'clustersite',
       	value => 'time.ncsu.edu',
    }

    xcat_site_attribute { "xcatroot" :
       	sitename => 'clustersite',
        value => "/opt/xcat",
    }

    xcat_site_attribute	{ "xcatprefix" :
        sitename => 'clustersite',
       	value => "/opt/xcat",
    }

    xcat_network { $private_domain :
        mgtifname => $private_if,
       	nameservers => "xcatmaster",
       	gateway	=> "xcatmaster",
       	domain => "private.netlabs",
       	net => $private_net,
       	mask =>	$private_mask,
        dynamicrange => $private_range,
    }

    xcat_network { $ipmi_domain :
       	mgtifname => $ipmi_if,
        nameservers => "xcatmaster",
        gateway => "xcatmaster",
        domain => "ipmi.netlabs",
        net => $ipmi_net,
        mask => $ipmi_mask,
        dynamicrange => $ipmi_range,
    }
}
