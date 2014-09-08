include stdlib
include xcat

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


class vclmgmt(
	$public_mac, 
	$public_if 	= 'em1', 
	$public_ip 	= 'dhcp', 
	$private_mac, 
	$private_ip, 
	$private_if 	= 'em2', 
	$private_domain, 
	$ipmi_mac, 
	$ipmi_ip, 
	$ipmi_if 	= 'p4p1', 
	$vcldb 		= 'vcl', 
	$vcluser 	= 'vcluser', 
	$root_pw, 
	$vcluser_pw, 
	$vclhost 	= 'localhost', 
	$serverip 	= 'localhost', 
	$xmlrpc_pw 	= 'just_another_password', 
	$xml_url 	= 'localhost',
	$pods 		= undef,
    	$vcldir 	= $vclmgmt::params::vcldir,
    	$dojo		= $vclmgmt::params::dojo,
    	$vclweb 	= $vclmgmt::params::vclweb,
    	$vclnode 	= $vclmgmt::params::vclnode,
    	$vclimages	= "${vcldir}/images",
) inherits vclmgmt::params {

	$htinc = "${vclweb}/.ht-inc"
	
	$postfiles = {
	        "${vclweb}"	=> {
	        	ensure 	=> "link",
	        	path	=> "${vclweb}",
	        	target 	=> "${vcldir}/web",
	        },
	        "${vclnode}"	=> {
	        	ensure 	=> "link",
	        	path	=> "${vclnode}",
	        	target	=> "${vcldir}/managementnode",
	        },
	    	"${vclweb}/dojo" => {
	        	ensure 	=> "link",
	    		path	=> "${vclweb}/dojo",
	    		target 	=> "${vclweb}/dojo-release-${dojo}",
	    	},
	    	"${vclweb}/dojo/vcldojo" => {
	        	ensure 	=> "link",
	    		path	=> "${vclweb}/dojo/vcldojo",
	    		target	=> "${vclweb}/js/vcldojo",
	    	},
	    	"maintenance" => {
			path	=> "${htinc}/maintenance",
			ensure  => "directory",
			owner   => "apache",
		},
		"vcld" => {
			path	=> '/etc/init.d/vcld',
			ensure	=> "present",
			mode	=> "a+x",
			tag	=> "postcopy",
		},
		"images" => {
			path	=> $vclimages,
			ensure 	=> "directory",
		}
	}
	
	$vclcopyfiles = {
# 		Will copy / edit this via Augeas in future versions
#    		'vcldconf' => {
#    			path 	=> "${vcldir}/managementnode/etc/vcl/vcld.conf",
#    			tgtdir	=> '/etc/vcl',
#    			target	=> 'vcld.conf',
#    		}, 
	    	'vcld' => {
	    		path	=> "${vcldir}/managementnode/bin/S99vcld.linux",
	    		tgtdir	=> '/etc/init.d',
	    		target	=> 'vcld',
	    	},
	}
	
	$configs = {
	    	'secrets' => {
	    		path	=> "${htinc}/secrets.php",
			content	=> template('vclmgmt/secrets.php.erb'),
		},
		# Remove this in future version, once copy / edit works above
		'vcldconf' => {
			path	=> "/etc/vcl/vcld.conf",
			content => template('vclmgmt/vcld.conf.erb'),
		},
		'confphp' => {
			path	=> "${htinc}/conf.php",
			content => template('vclmgmt/conf.php.erb'),
		},
	}

	$myfirewalls = {
		'110 accept forward from me across bridges' => {
        		chain => 'FORWARD',
        		proto => 'all',
        		action => 'accept',
			source => $private_ip,
		},
    		"115 accept tftp" => {
        		chain => 'INPUT',
        		proto => 'udp',
        		dport => 69,
        		action => 'accept',
        		destination => $private_ip,
    		},
        	"116 accept sending tftp" => {
        	        chain => 'INPUT',
        	        proto => 'udp',
        	        dport => 69,
        	        action => 'accept',
        	        source => $private_ip,
        	},
		"117 accept xcat calls 3001" => {
                        chain => 'INPUT',
                        proto => 'tcp',
                        dport => 3001,
                        action => 'accept',
                        destination => $private_ip,
                },
                "118 accept xcat calls 3002" => {
                        chain => 'INPUT',
                        proto => 'tcp',
                        dport => 3002,
                        action => 'accept',
                        destination => $private_ip,
                },
	}

	$firewalls = merge($vclmgmt::params::firewalls, $myfirewalls) 
	
	define vclmgmt::vclcopy(
		$path,
		$tgtdir,
		$target,
	) {
		file { $tgtdir :
			ensure  => "present",
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
	
	package { $vclmgmt::params::pkg_list:
		ensure => "latest", 
		provider => "yum", 
		tag	 => "vclinstall",
	}
	package { $vclmgmt::params::pkg_exclude: 
		ensure => "absent", 
	}
	
	vclmgmt::cpan { $vclmgmt::params::cpan_list: }
	
	file { $vcldir :
		ensure  => "directory",
	} ->
	subversion::checkout { "vcl" :
		repopath	=> "/repos/asf/vcl/trunk",
		workingdir	=> $vcldir,
		host		=> "svn.apache.org",
		method		=> "http",
		#revision	=> "",
	} ->
	archive { "dojo-release-${dojo}" :
		url	=> "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${dojo}.tar.gz",
		target	=> "${vcldir}/web/",
		ensure 	=> present,
	    	timeout => 0,
	}
	
	create_resources(file, $postfiles, { tag => "vclpostfiles", })
	
	create_resources(file, $configs, $vclmgmt::params::configfile)
	
	create_resources(vclmgmt::vclcopy, $vclcopyfiles)
    
	exec { 'genkeys' :
		command => '/bin/sh genkeys.sh',
		cwd	=> $htinc,
		creates	=> "${htinc}/keys.pem",
    	}
    
    	create_resources(firewall, $firewalls, $vclmgmt::params::firedefaults)
    
    	if str2bool("$selinux") {
    		create_resources(selboolean, $vclmgmt::params::sebools)
    	}

    	create_resources(service, $vclmgmt::params::service_list, $vclmgmt::params::servicedefault)
    
    	if $pods == undef {
		$dhcpinterfaces = [ $private_if, $ipmi_if ]
	}
	else {
		$dhcpinterfaces = list_vlans($pods, $private_if, $ipmi_if)
	}	

	network::if::static { $private_if :
		ensure => 'up',
		ipaddress => $private_ip,
		netmask   => '255.255.255.0',
		macaddress => $private_mac,
		require => Class['vclmgmt::params'],
	}
	network::if::static { $ipmi_if :
		ensure => 'up',
		ipaddress => $ipmi_ip,
		netmask   => '255.255.255.0',
		macaddress => $ipmi_mac,
		require => Class['vclmgmt::params'],
	}

	if $public_ip == 'dhcp' {
		network::if::dynamic { $public_if :
			ensure => 'up',
			macaddress => $public_mac,
			bootproto => 'dhcp',
#			peerdns	=> 'no',
			require => Class['vclmgmt::params'],
		}
	}
	else {
		network::if::static { $public_if :
			ensure => 'up',
			ipaddress => $public_ip,
			netmask   => '255.255.255.0',
			macaddress => $public_mac,
			require => Class['vclmgmt::params'],
		}
	}

	class {'::mysql::server':
		root_password => $root_pw,
		require => Class['vclmgmt::params'],
	}
	
	mysql::db { $vcldb :
		user => $vcluser,
		password => $vcluser_pw,
		host => 'localhost',
		grant => ['GRANT', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TEMPORARY TABLES'],
		sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
	}

        xcat_site_attribute { "master" :
		sitename => 'clustersite',
		value => $fqdn,
	}
	
	xcat_site_attribute { "nameservers" :
		sitename => 'clustersite',
		value => $private_ip,
	}
	
	xcat_site_attribute { "dhcpinterfaces" :
		sitename => 'clustersite',
		value => $dhcpinterfaces,
	}
	
	xcat_site_attribute { "domain" :
		sitename => 'clustersite',
		value => $private_domain,
	}
	
	xcat_site_attribute { "ntpservers" :
	       sitename => 'clustersite',
	       value => 'time.ncsu.edu',
	}
	
	xcat_site_attribute { "xcatroot" :
	       	sitename => 'clustersite',
		value => "/opt/xcat",
	}
	
	xcat_site_attribute	{ "xcatprefix" :
		sitename => 'clustersite',
	       	value => "/opt/xcat",
	}

#	class { 'dhcp::server':
#        #	opts => ['domain-name "toto.ltd"',
#        #               'domain-name-servers 192.168.21.1'],                      
#        }
#
#	include bind
#
	if $pods != undef {
		$newpods = set_defaults($pods, $private_if, $private_ip, $private_mac, $ipmi_if, $ipmi_ip, $ipmi_mac)
		create_resources(vclmgmt::xcat_pod, $newpods)
	}

        exec { "makehosts" :
                command => "/opt/xcat/sbin/makehosts",
                refreshonly => "true",
        }~>
        exec { "makedhcpn" :
                command => "/opt/xcat/sbin/makedhcp -n",
                refreshonly => "true",
        }~>
        exec { "makedhcpa" :
                command => "/opt/xcat/sbin/makedhcp -a",
                refreshonly => "true",
        }~>
        exec { "makedns"  :
                command => "/opt/xcat/sbin/makedns -n",
                refreshonly => "true",
        }

        Exec["makehosts"] <~ Vclmgmt::Compute_node <| |>
        Exec["makehosts"] <~ Vclmgmt::Xcat_pod <| |>
	
	Yumrepo <| tag == "vclrepos" |> -> Package <| tag == "vclinstall" |> -> Vclmgmt::Cpan <| |> -> Subversion::Checkout[ 'vcl'] 
    	Archive ["dojo-release-${dojo}"] -> File <| tag == "vclpostfiles" and tag != "postcopy" |> -> Vclmgmt::Vclcopy <| |> -> File <| tag == "postcopy" |> -> Mysql::Db[$vcldb] -> Exec['genkeys'] -> Service <| name == $vclmgmt::params::service_list |>
    
    	File['vcldconf'] ~> Service['vcld']
    	Subversion::Checkout['vcl'] ~> Vclmgmt::Vclcopy <| |>
    
	Class['mysql::server']-> Mysql::Db[$vcldb]
	Package<| |> -> Xcat_site_attribute <| |> ~> Service['xcatd']

	Xcat_network <| |> -> Xcat_node<| |> -> Package <| |>

}

