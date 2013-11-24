class vclmgmt::puppetmaster {
    class { 'puppet::master':
        storeconfigs => true,
    }

    include $vclmgmt::params

    puppet::masterenv { $vclmgmt::params::puppetenvs:
        modulepath => "/etc/puppet/env/{$name}/modules",
        manifest => "/etc/puppet/env/{$name}/site.pp",
        require => Class['vclmgmt::params'],
    }
}
