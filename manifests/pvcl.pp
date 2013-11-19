class vclmgmt::vcldirs {
	define vclmgmt::vcldirs::mylinks() {
		include vclmgmt::params
		$mytarget = $vclmgmt::params::vcllinktargets[$name]

		file { $name :
			ensure => "link",
			target => $mytarget,
			require => Class["vclmgmt::subversion"],
		}    
	}

	define vclmgmt::vcldirs::vclcopy() {
		include vclmgmt::params
		$mytarget 	= $vclmgmt::params::vclcptargets[$name]
		$mydir 		= $vclmgmt::params::vclcptgtdirs[$name]

		exec { "mkdir sample" :
			unless => "ls ${mydir}"
		}

		exec { "cp ${name} ${mytarget}" :
			require => Class["vclmgmt::subversion"],
		}
	}

	vclmgmt::vcldirs::vclcopy { $vclmgmt::params::vclcopyfiles :

	}

	vclmgmt::vcldirs::mylinks { $vclmgmt::params::vcllinks :
		
	}

	file { "maintenance" :
		path	=> $vclmgmt::params::maintenance,
		ensure  => "directory",
		owner   => "apache",
	        require => Class["vclmgmt::subversion"],
	}

	file { "vcld" :
		path	=> $vclmgmt::params::vclcptargets[$vclmgmt::params::vcld],
		ensure	=> "present",
		mode	=> "a+x",
	}

	file { "images" :
		path	=> $vclmgmt::params::vclimages,
		ensure 	=> "directory",
		require => Class["vclmgmt::subversion"],
	}
}