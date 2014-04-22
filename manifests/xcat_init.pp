include vclmgmt

define vclmgmt::xcat_init($ipmi_if, $private_if, $dhcpinterfaces, $private_ip, $private_domain)  {

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
	value => $dhcpinterfaces,
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
}
