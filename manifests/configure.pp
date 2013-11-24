define vclmgmt::configure($vclhost, $vcldb, $vcluser, $vcluser_pw, $helpemail = 'netlabs@help.ncsu.edu' , $serverip, $xmlrpc_pw, $xml_url) {
	include $vclmgmt::params

	file { "${vclmgmt::params::htinc}/secrets.php" :
		ensure => file,
		# path	=> "/var/www/html/vcl/.ht-inc",
		#owner	=> $vcluser,
		#password => $vcluser_pw,
		mode	=> '0644',
		content	=> template('vclmgmt/secrets.php.erb'),
		require => Class['vclmgmt::vcldirs'],
	}
	notify {'sercrets.php.erb has already been updated.':}

	file{ "/etc/vcl/vcld.conf" :
		ensure => file,
		mode => '0644',
		content => template('vclmgmt/vcld.conf.erb'),
		require => Class['vclmgmt::vcldirs'],

	}

	file{ "${vclmgmt::params::htinc}/conf.php" :
		ensure => file,
		mode => '0644',
		content => template('vclmgmt/conf.php.erb'),
		require => Class['vclmgmt::vcldirs']
	}
#	notify{$fqdn :}
 	notify{'vcld.conf updated.':}

    }
