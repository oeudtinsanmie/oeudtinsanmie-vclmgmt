class vclmgmt::installfrom {
    yumrepo { $vclmgmt::params::xcatcore :
        descr => $vclmgmt::params::xcatcore_desc,
        baseurl => $vclmgmt::params::xcatcore_mirror,
        enabled => 1,
	gpgcheck => 1,
	gpgkey => $vclmgmt::params::xcatcore_key,
        require => Class["vclmgmt::params"],
    }

    yumrepo { $vclmgmt::params::xcatdep :
        descr => $vclmgmt::params::xcatdep_desc,
        baseurl => $vclmgmt::params::xcatdep_mirror,
        enabled => 1,
	gpgcheck => 1,
	gpgkey => $vclmgmt::params::xcatdep_key,
        require => Class["vclmgmt::params"],
    }
}
