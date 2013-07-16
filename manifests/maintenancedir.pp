class vclmgmt::maintenancedir {
	File { $vclmgmt::params::maintenance :
		ensure  => "directory",
		owner   => "apache",
	        require => Class["vclmgmt::subversion"],
	}
}
