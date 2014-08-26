define vclmgmt::mylinks() {
		include vclmgmt::params
		$mytarget = $vclmgmt::params::vcllinktargets[$name]

		file { $name :
			ensure => "link",
			target => $mytarget,
			require => Class["vclmgmt::subversion"],
		}    
	}
