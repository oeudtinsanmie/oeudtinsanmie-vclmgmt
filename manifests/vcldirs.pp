class vclmgmt::vcldirs {

	define vclmgmt::vcldirs::vclcopy() {
		include vclmgmt::params
		$mytarget 	= $vclmgmt::params::vclcptargets[$name]
		$mydir 		= $vclmgmt::params::vclcptgtdirs[$name]

		exec { "mkdir ${mydir}" :
			require => Class["vclmgmt::subversion"],
			unless => "ls ${mydir}"
		}

		exec { "cp ${name} ${mytarget}" :
			require => Class["vclmgmt::subversion"],
		}
	}

	vclmgmt::vcldirs::vclcopy { $vclmgmt::params::vclcopyfiles :

	}

	vclmgmt::mylinks { $vclmgmt::params::vcllinks :
		
	}

	file { "maintenance" :
		path	=> "${vclmgmt::params::htinc}/maintenance",
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
