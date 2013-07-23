class vclmgmt::subversion {
	include $vclmgmt::params

	File { $vclmgmt::params::vcldir :
		ensure  => "directory",
	        require => Class["vclmgmt::params"],
	}
	
	subversion::checkout { "vcl" :
		repopath	=> "/viewvc/vcl/trunk",
		workingdir	=> $vclmgmt::params::vcldir,
		host		=> "svn.apache.org",
		method		=> "http",
		#revision	=> "",
		require		=> File[$vclmgmt::params::vcldir],
	        require 	=> Class["vclmgmt::yuminstall"],
	}
}
