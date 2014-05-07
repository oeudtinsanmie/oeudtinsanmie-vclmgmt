include vclmgmt

define vclmgmt::baseimage(
	$prettyname, 
	$platform, 
	$os, 
	$minram		= 512,
	$minprocnumber	= 1,
	$minprocspeed	= 1024,
	$minnetwork	= 100,
	$maxconcurrent	= undef,
	$test		= 1,
	$lastupdate	= undef,
	$forcheckout	= 1,
	$project	= 'vcl',
	$size		= 1500,
	$architecture	= 'x86_64',
	$description	= undef,
	$usage		= undef,
	
	$url		= undef,
	$filepath,
	$distro,
) {
        vcl_image { $name :
        	prettyname 	=> $prettyname, 
		platform  	=> $platform, 
		os 		=> $os, 
		minram		=> $minram,
		minprocnumber	=> $minprocnumber,
		minprocspeed	=> $minprocspeed,
		minnetwork	=> $minnetwork,
		maxconcurrent	=> $maxconcurrent,
		test		=> $test,
		lastupdate	=> $lastupdate,
		forcheckout	=> $forcheckout,
		project		=> $project,
		size		=> $size,
		architecture	=> $architecture,
		description	=> $description,
		usage		=> $usage,
        }
        
        xcat::image{ "${name}-img" :
		url 	 => $url,
		filepath => $filepath,
		distro 	 => $distro,
		arch	 => $architecture,
	}
}
