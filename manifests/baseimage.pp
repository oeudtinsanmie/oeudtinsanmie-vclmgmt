include vclmgmt

define vclmgmt::baseimage(
        $ensure		= present,
	$prettyname, 
	$platform	= 'i386', 
	$os, 
	$minram		= 512,
	$minprocnumber	= 1,
	$minprocspeed	= 1024,
	$minnetwork	= 100,
	$maxconcurrent	= undef,
	$test		= false,
	$forcheckout	= true,
	$project	= 'vcl',
	$size		= 1500,
	$architecture	= 'x86_64',
	$description	= undef,
	$usage		= undef,
        $deleted	= false,
	
	$url		= undef,
	$filepath,
	$distro,
) {
        vcl_image { $name :
		ensure		=> $ensure,
        	prettyname 	=> $prettyname, 
		platform  	=> $platform, 
		os 		=> $os, 
		minram		=> $minram,
		minprocnumber	=> $minprocnumber,
		minprocspeed	=> $minprocspeed,
		minnetwork	=> $minnetwork,
		maxconcurrent	=> $maxconcurrent,
		test		=> $test,
		forcheckout	=> $forcheckout,
		project		=> $project,
		size		=> $size,
		architecture	=> $architecture,
		description	=> $description,
		usage		=> $usage,
		deleted		=> $deleted,
        }
        
        xcat::image{ "${name}-img" :
		ensure   => $ensure,
		url 	 => $url,
		filepath => $filepath,
		distro 	 => $distro,
		arch	 => $architecture,
	}
}
