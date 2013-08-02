class vclmgmt::mysql {
    class {'mysql::server': 
        config_hash => { 'root_password' => $vclmgmt::params::sqlroot },
        require => Class['vclmgmt::params'],
    }
    Database {
        require => Class['mysql::server'],
	provider => 'mysql',
    }

    mysql::db { 'vcl' :
	user => 'root',
	password => $vclmgmt::params::sqlroot,
	host => 'localhost',
	grant => 'all',
        sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
        require => Class['vclmgmt::subversion'],
    }

    database_user { 'vcluser@localhost' :
	password_hash => mysql_password($vclmgmt::params::vclpassword),
    }

    database_grant { 'vcluser@localhost/vcl' :
        privileges => ['GRANT_priv', 'SELECT_priv', 'INSERT_priv', 'UPDATE_priv', 'DELETE_priv', 'Create_tmp_table_priv'],
    }
}
