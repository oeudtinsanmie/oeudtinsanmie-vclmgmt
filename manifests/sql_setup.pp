
define vclmgmt::sql_setup($vcldb, $vcluser, $root_pw, $vcluser_pw) {
    class {'::mysql::server':
        root_password => $root_pw,
        require => Class['vclmgmt::params'],
    }

    mysql::db { $vcldb :
        user => $vcluser,
        password => $vcluser_pw,
        host => 'localhost',
        grant => ['GRANT', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TEMPORARY TABLES'],
        sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
        require => Class['vclmgmt::subversion'],
    }

    Class['mysql::server']->Mysql::Db[$vcldb]
}
