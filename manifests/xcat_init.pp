include vclmgmt

define vclmgmt::xcat_init($ipmi_ip, $ipmi_net, $ipmi_mask, $ipmi_if, $ipmi_user, $ipmi_pw, $admin_user, $admin_pw, $private_net, $private_mask, $private_if)  {
    xcat_node { "ipmi" :
        bmc => "/\\\\z/-ipmi/",
        bmcusername => $ipmi_user,
        bmcpassword => $ipmi_pw,
        domainadminuser => $admin_user,
        domainadminpassword => $admin_pw,
        mgt => "ipmi",
    }

    xcat_site_attribute { "master" :
        sitename => 'clustersite',
        value => $ipmi_ip,
    }

    xcat_site_attribute { "dhcpinterfaces" :
	sitename => 'clustersite',
	value => [$private_if, $ipmi_if],
    }

    xcat_network { "private" :
        mgtifname => $private_if,
       	nameservers => "<xcatmaster>",
       	gateway	=> "<xcatmaster>",
       	domain => "private.netlabs",
       	net => $private_net,
       	mask =>	$private_mask,
    }

    xcat_network { "ipmi" :
       	mgtifname => $ipmi_if,
        nameservers => "<xcatmaster>",
        gateway => "<xcatmaster>",
        domain => "ipmi.netlabs",
        net => $ipmi_net,
        mask => $ipmi_mask,
    }
}
