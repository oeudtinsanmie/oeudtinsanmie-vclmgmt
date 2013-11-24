<<<<<<< HEAD
define vcl_mgmt::configure($vclhost, $vcldb, $vcluser, $vcluser_pw) {
	file { "secrets.php" :
	#	path	=> "/var/www/html/vcl/.ht-inc",
		owner	=> $vcluser,
		password => $vcluser_pw,
		mode	=> '0644',
		content	=> template('../templates/secrets.php.erb')
	}
	notify {'templates/sercrets.php.erb has already been updated.':}
 	
	file { "secrets.php" :
        ensure => symlink,
        # path   => "/var/www/html/vcl/.ht-inc",
        target => '../templates/secrets_new.php'
      }
=======
define vclmgmt::configure($vclhost, $vcldb, $vcluser, $vcluser_pw) {
	
	file { "/var/www/html/vcl/.ht-inc/secrets.php" :
		ensure => file,
		# path	=> "/var/www/html/vcl/.ht-inc",
		#owner	=> $vcluser,
		#password => $vcluser_pw,
		mode	=> '0644',
		content	=> template('vclmgmt/secrets.php.erb'),
		require => Class['vclmgmt::subversion'],
	}
	notify {'sercrets.php.erb has already been updated.':}
 	
>>>>>>> origin/dev
    }
