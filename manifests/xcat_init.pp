include vclmgmt

define vclmgmt::xcat_init($ipmi_ip, $ipmi_user, $ipmi_pw, $admin_user, $admin_pw)  {
    xcat_node { "ipmi" :
        bmc => "/\\z/—ipmi/",
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
}
