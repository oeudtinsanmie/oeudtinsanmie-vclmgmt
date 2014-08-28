# Class: mgmt
#
# This module manages mgmt
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]


class vclmgmt inherits vclmgmt::params {	
    define vclmgmt::vclcopy(
	$path,
	$tgtdir,
	$target,
    ) {
	file { $tgtdir :
		ensure => "directory",
	} ->
	exec { "cp ${path} ${tgtdir}/${target}" :
		refreshonly => true,
	}
    }
    
    # TODO: More complete cpan provider to allow optional updates
    define vclmgmt::cpan() {
	exec { "/usr/bin/cpanp -i --skiptest ${name}" :
		refreshonly => true,
	}
    }

    case $::osfamily {

    	'RedHat': {
    		create_resources(yumrepo, $vclmgmt::params::repos, $vclmgmt::params::defaultrepo)
    	}

    	default: {
      		fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    	}
    }
    
    create_resources(package, $vclmgmt::params::pkg_list, { ensure => "latest", provider => "yum", })
    create_resources(package, $vclmgmt::params::pkg_exclude, { ensure => "absent", })
    
    create_resources(vclmgmt::cpan, $vclmgmt::params::cpan_list)
    
    file { $vclmgmt::params::vcldir :
	ensure  => "directory",
    } ->
    subversion::checkout { "vcl" :
	repopath	=> "/repos/asf/vcl/trunk",
	workingdir	=> $vclmgmt::params::vcldir,
	host		=> "svn.apache.org",
	method		=> "http",
	#revision	=> "",
    } ->
    archive { "dojo-release-${vclmgmt::params::dojo}" :
	url	=> "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${vclmgmt::params::dojo}.tar.gz",
	target	=> "${vcldir}/web/",
	ensure 	=> present,
    	timeout => 0,
    }
    
    create_resources(file, $vclmgmt::params::postfiles)
    
    create_resources(file, $vclmgmt::params::configs, $vclmgmt::params::configfile)
    
    create_resources(vclmgmt::vclcopy, $vclmgmt::params::vclcopyfiles)
    
    exec { 'genkeys' :
	command => '/bin/sh genkeys.sh',
	cwd	=> $vclmgmt::params::htinc,
	creates	=> "${vclmgmt::params::htinc}/keys.pem",
    }
    
    create_resources(firewall, $vclmgmt::params::firewalls, $vclmgmt::params::firedefaults)
    
    if str2bool("$selinux") {
    	create_resources(selboolean, $vclmgmt::params::sebools)
    }

    create_resources(service, $vclmgmt::params::service_list, $vclmgmt::params::servicedefault)
    
    Yumrepo <| |> -> Package <| |> -> Vclmgmt::Cpan <| |> -> Subversion::Checkout <| |> 
    Archive ["dojo-release-${vclmgmt::params::dojo}"] -> File <| name != $vclmgmt::params::vcldir |> -> Exec['genkeys'] -> Service <| |>
    
    File['vcldconf'] ~> Service['vcld']
    Subversion::Checkout['vcl'] ~> Vclmgmt::Copy <| |>
}
