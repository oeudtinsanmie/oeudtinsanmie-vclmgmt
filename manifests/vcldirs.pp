class vclmgmt::vcldirs {
	define vclmgmt::maintenancedir::mylinks() {
		include vclmgmt::params
		$mytarget = $vclmgmt::params::vcltargets[$name]

		file { $mytarget : 
			ensure => "present",
			recurse => "true",
		}

		file { $name :
			ensure => "link",
			target => $mytarget,
			require => Class["vclmgmt::subversion"],
		}    
	}
	vclmgmt::maintenancedir::mylinks { $vclmgmt::params::vcllinks :
		
	}

	file { "maintenance" :
		path	=> $vclmgmt::params::maintenance,
		ensure  => "directory",
		owner   => "apache",
	        require => Class["vclmgmt::subversion"],
	}
}
