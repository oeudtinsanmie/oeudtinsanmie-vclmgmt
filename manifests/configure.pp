define vclmgmt::configure($vclhost, $vcldb, $vcluser, $vcluser_pw, $helpemail = 'netlabs@help.ncsu.edu' , $serverip, $xmlrpc_pw, $xml_url) {
	include $vclmgmt::params

	file { 'secrets' : 
		path	=> "${vclmgmt::params::htinc}/secrets.php",
		ensure 	=> file,
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

	exec { 'genkeys' :
		command => '/bin/sh genkeys.sh',
		cwd	=> $vclmgmt::params::htinc,
		creates	=> "${vclmgmt::params::htinc}/keys.pem",
	}
	
	archive { "dojo-release-${vclmgmt::params::dojo}" :
		ensure 	=> present,
		url	=> "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${vclmgmt::params::dojo}.tar.gz",
		target	=> vclmgmt::params::vclweb,
                timeout => 0,
                require => File['secrets'],
	}
	
	Archive["dojo-release-${vclmgmt::params::dojo}"]->File["${vclmgmt::params::vclweb}/dojo"]->File["${vclweb}/dojo/vcldojo"]
	
	File['secrets']->Exec['genkeys']

    }
