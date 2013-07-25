class vclmgmt::services {
    Service {
        ensure => running,
        hasstatus => true,
        hasrestart => true,
        enable => true,
        require => Class["vclmgmt::vcldirs"],
    }

    include $vclmgmt::params

    service { $vclmgmt::params::service_list : }
}
