class vclmgmt::services {
    Service {
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["vclmgmt::yuminstall"],
    }

    service { $vclmgmt::params::service_list : }
}
