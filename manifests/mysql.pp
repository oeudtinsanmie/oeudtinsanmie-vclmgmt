class vclmgmt::mysql {
    Database {
        require => Class['mysql::server'],
    }
    class {'mysql::server': 
        config_hash => { 'root_password' => $vclmgmt::params::sqlroot },
        require => Class['vclmgmt::params'],
    }
    
    mysql::db { 'vcl':
        user => 'vcluser',
        password => $vclmgmt::params::vclpassword,
        host => 'localhost',
        grant => ['GRANT', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TEMPORARY TABLES'],
        sql => "{$vclmgmt::params::vcldir}/mysql/vcl.sql",
        require => Class['vclmgmt::subversion'],
    }
}
