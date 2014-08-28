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


class vclmgmt {	
    include xcat
    include vclmgmt::params

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
    }
    
    create_resources(archive, $vclmgmt::params::archives, $vclmgmt::params::webarchive)
    
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
    
    Yumrepo <| |> -> Package <| |> -> Vclmgmt::Cpan <| |> -> Subversion::Checkout <| |> -> Archive <| |> -> File <| name != $vclmgmt::params::vcldir |> -> Exec['genkeys'] -> Service <| |>
    
    File['vcldconf'] ~> Service['vcld']
    Subversion::Checkout['vcl'] ~> Vclmgmt::Copy <| |>
}
