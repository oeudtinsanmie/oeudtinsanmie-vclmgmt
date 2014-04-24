
define vclmgmt::sql_setup($vcldb, $vcluser, $root_pw, $vcluser_pw) {
    class {'::mysql::server':
        root_password => $vclmgmt::params::sqlroot,
        require => Class['vclmgmt::params'],
    }
    Database {
	require => Class['::mysql::server'],
        provider => 'mysql',
    }

    mysql::db { $vcldb :
	user => 'root',
	password => $root_pw,
	host => 'localhost',
	grant => 'all',
	sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
	require => Class['vclmgmt::subversion'],
    }

    mysql_user { "${vcluser}@localhost" :
	ensure => present,
	password_hash => mysql_password($vcluser_pw),
	require => Class['::mysql::server'],
    }

    mysql_grant { "${vcluser}@localhost/${vcldb}" :
	ensure => present,
#	privileges => ['GRANT_priv', 'SELECT_priv', 'INSERT_priv', 'UPDATE_priv', 'DELETE_priv', 'Create_tmp_table_priv'],
        privileges => ['GRANT', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TEMPORARY TABLES'],
	table => '*.*',
        require	=> Class['::mysql::server'],
	user => "${vcluser}@localhost",
    }
}
