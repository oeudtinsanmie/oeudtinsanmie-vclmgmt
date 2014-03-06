include vclmgmt

define vclmgmt::xcat_init($ipmi_ip, $ipmi_user, $ipmi_pw, $admin_user, $adimin_pw)  {
    xcat_node { “ipmi” :
        bmc => “/\\z/—ipmi/“,
        bmcusername => $ipmi_user,
        bmcpassword => $ipmi_pw,
        domainadminuser => $admin_user,
        domainadminpassword => $admin_pw,
    }

    xcat_site_attribute { “master” :
        
        value => $ipmi_ip,
    }
}
