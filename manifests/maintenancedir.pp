class vclmgmt::maintenancedir {
	File { $vclmgmt::params::maintenance :
		ensure  => "directory",
		owner   => "apache",
	        require => Class["vclmgmt::subversion"],
	}
	

	define vclmgmt::maintenancedir::mylinks() {
		include vclmgmt::params
		$mytarget = $vclmgmt::params::vcltargets[$name]

		File { $name :
			ensure => "link",
			target => $mytarget,
			require => Class["vclmgmt::params"],
		}    
	}
	vclmgmt::maintenancedir::mylinks($vclmgmt::params::vcllinks) {
		
	}
}
