class vclmgmt::yuminstall {
    Package { 
        ensure => "latest",
        require => Class["vclmgmt::installfrom"],
    }

    package { $vclmgmt::params::pkg_list : }

    package { $vclmgmt::params::pkg_exclude :
        ensure => "absent",
    }
}
