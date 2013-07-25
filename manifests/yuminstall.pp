class vclmgmt::yuminstall {
    Package { 
        ensure => "latest",
        provider => "yum",
        require => Class["vclmgmt::installfrom"],
    }

    include $vclmgmt::params

    package { $vclmgmt::params::pkg_list : }

    package { $vclmgmt::params::pkg_exclude :
        ensure => "absent",
    }
}
