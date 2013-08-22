class vclmgmt::mysql {
    class {'mysql::server': 
        config_hash => { 'root_password' => $vclmgmt::params::sqlroot },
        require => Class['vclmgmt::params'],
    }
    Database {
        require => Class['mysql::server'],
	provider => 'mysql',
    }

}
