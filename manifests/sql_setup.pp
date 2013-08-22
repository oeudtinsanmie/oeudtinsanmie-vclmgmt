include vclmgmt::mysql

define vclmgmt::sql_setup($vcldb, $vcluser, $root_pw, $vcluser_pw) {

    mysql::db { $vcldb :
	user => 'root',
	password => $root_pw,
	host => 'localhost',
	grant => 'all',
	sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
	require => Class['vclmgmt::subversion'],
    }

    database_user { $vcluser :
	password_hash => mysql_password($vclmgmt::params::vclpassword),
    }

    database_grant { "${vcluser}/${vcldb}" :
	privileges => ['GRANT_priv', 'SELECT_priv', 'INSERT_priv', 'UPDATE_priv', 'DELETE_priv', 'Create_tmp_table_priv'],
    }
}
