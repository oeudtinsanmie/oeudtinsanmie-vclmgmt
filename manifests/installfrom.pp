class vclmgmt::installfrom {
    include vclmgmt::params
    notify {"yum repos xcat-core {$vclmgmt::params::xcatcore}, {$vclmgmt::params::xcatcore_desc}, {$vclmgmt::params::xcatcore_mirror}" : }
    notify {"yum repos xcat-dep {$vclmgmt::params::xcatdep}, {$vclmgmt::params::xcatdep_desc}, {$vclmgmt::params::xcatdep_mirror}" : }

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

    yumrepo { $vclmgmt::params::centos :
        descr => $vclmgmt::params::centos_desc,
        baseurl => $vclmgmt::params::centos_mirror,
        enabled => 1,
	gpgcheck => 1,
	gpgkey => $vclmgmt::params::centos_key,
        require => Class["vclmgmt::params"],
    }

    yumrepo { $vclmgmt::params::fedora :
        descr => $vclmgmt::params::fedora_desc,
        baseurl => $vclmgmt::params::fedora_mirror,
        enabled => 1,
	gpgcheck => 1,
	gpgkey => $vclmgmt::params::fedora_key,
        require => Class["vclmgmt::params"],
    }
}
