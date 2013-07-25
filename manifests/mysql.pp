class vclmgmt::mysql {
    class {'mysql::server': 
        config_hash => { 'root_password' => $vclmgmt::params::sqlroot },
        require => Class['vclmgmt::params'],
    }
    Database {
        require => Class['mysql::server'],
    }
    
    mysql::db { 'vcl':
        user => 'vcluser',
        password => $vclmgmt::params::vclpassword,
        host => 'localhost',
        grant => ['GRANT_priv', 'SELECT_priv', 'INSERT_priv', 'UPDATE_priv', 'DELETE_priv', 'Create_tmp_table_priv'],
        sql => "{$vclmgmt::params::vcldir}/mysql/vcl.sql",
        require => Class['vclmgmt::subversion'],
    }
}
