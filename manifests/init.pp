include stdlib

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
	$system_user = 'root',
	$system_pw,
	$vclhost 	= 'localhost', 
	$serverip 	= 'localhost', 
	$xmlrpc_pw 	= 'just_another_password', 
	$xml_url 	= 'localhost',
	$poddefaults	= {},
	$pods 		= undef,
	$vcldir 	= $vclmgmt::params::vcldir,
	$dojo		= $vclmgmt::params::dojo,
	$dojo_checksum	= $vclmgmt::params::dojo_checksum,
	$vclweb 	= $vclmgmt::params::vclweb,
	$vclnode 	= $vclmgmt::params::vclnode,
	$vclimages	= undef,
  $firewalldefaults = {
    require => Class['ncsufirewall::pre'],
    before  => Class['ncsufirewall::post'],
  },
) inherits vclmgmt::params {

	class { "xcat": }

	$htinc = "${vclweb}/.ht-inc"
	
	if $vclimages == undef {
    $vclimgs = "${vcldir}/images"  
	}
	else {
	  $vclimgs = $vclimages 
	}
	
	
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
			path	=> $vclimgs,
			ensure 	=> "directory",
		},
		"etcvcl" => {
			path	=> "/etc/vcl",
			ensure	=> "directory",
		},
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

	# These files really should be served somewhere from the VCL project
	# Temporary workarounds:
	define vclmgmt::regexfile ($root, $tgt) {
		file { $name :
			source 	=> "puppet:///modules/vclmgmt/${tgt}/${name}",
			path	=> "${root}/${tgt}/${name}",
		} 		
	}
	
	file { $vcldir :
		ensure  => "directory",
	} ->
	vcsrepo { "vcl" :
    ensure => present,
    path  => $vcldir,
    provider => svn,
    source   => "http://svn.apache.org/repos/asf/vcl/trunk",
	} ->
	archive { "dojo-release-${dojo}" :
		url	=> "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${dojo}.tar.gz",
		target	=> "${vcldir}/web/",
		ensure 	=> present,
	    	timeout => 0,
		checksum=> $dojo_checksum,
	} 

	vclmgmt::regexfile { $vcldojo : 
		root => "${$vcldir}/web/dojo-release-${dojo}",
		tgt  => "dojo",
	}

	vclmgmt::regexfile { $vcldojonls : 
		root => "${$vcldir}/web/dojo-release-${dojo}",
		tgt  => "dojo/nls",
	}
	
	create_resources(file, $postfiles, { tag => "vclpostfiles", })
	
	create_resources(file, $configs, $vclmgmt::params::configfile)
	
	create_resources(vclmgmt::vclcopy, $vclcopyfiles)
    
	exec { 'genkeys' :
		command => '/bin/sh genkeys.sh',
		cwd	=> $htinc,
		creates	=> "${htinc}/keys.pem",
    	}
    
    	create_resources(firewall, $firewalls, $firewalldefaults)
    
    	if str2bool("$selinux") {
    		create_resources(selboolean, $vclmgmt::params::sebools)
    	}

    	create_resources(service, $vclmgmt::params::service_list, $vclmgmt::params::servicedefault)
    
    	if $pods == undef {
		$dhcpinterfaces = [ $private_if, $ipmi_if ]
	}
	else {
		$dhcpinterfaces = list_vlans($poddefaults, $pods, $private_if, $ipmi_if)
	}	

	network::if::static { $private_if :
		ensure => 'up',
		ipaddress => $private_ip,
		netmask   => '255.255.255.0',
		macaddress => $private_mac,
		require => Class['vclmgmt::params'],
	}
	$privatenet = split($private_ip, '\.')
	xcat_network { "${privatenet[0]}_${privatenet[1]}_${privatenet[2]}_0-255_255_255_0":
		ensure => absent,
	}
	network::if::static { $ipmi_if :
		ensure => 'up',
		ipaddress => $ipmi_ip,
		netmask   => '255.255.255.0',
		macaddress => $ipmi_mac,
		require => Class['vclmgmt::params'],
	}
	$ipminet = split($ipmi_ip, '\.')
	xcat_network { "${ipminet[0]}_${ipminet[1]}_${ipminet[2]}_0-255_255_255_0":
		ensure => absent,
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
	
	xcat_passwd_tbl { "system" :
	  username => $system_user,
	  password => $system_pw,
	}
	
	xcat_site_attribute	{ "xcatprefix" :
		sitename => 'clustersite',
	       	value => "/opt/xcat",
	}

	class { 'dhcp::server': }

	class {"bind": }

	if $pods != undef {
		$masterdefault = {
			private_if => $private_if,
			private_ip => $private_ip,
			private_mac => $private_mac,
			ipmi_if => $ipmi_if,
			ipmi_ip => $ipmi_ip,
			ipmi_mac => $ipmi_mac,
			system_user => $system_user,
			system_pw => $system_pw,
		}
		$newpods = set_defaults($pods, $poddefaults, $masterdefault)
		create_resources(vclmgmt::xcat_pod, $newpods)
	}

        exec { "makehosts" :
                command => "/opt/xcat/sbin/makehosts",
                refreshonly => "true",
        }
#~>
#        exec { "makedhcpn" :
#                command => "/opt/xcat/sbin/makedhcp -n",
#                refreshonly => "true",
#        }~>
#        exec { "makedhcpa" :
#                command => "/opt/xcat/sbin/makedhcp -a",
#                refreshonly => "true",
#        }~>
#        exec { "makedns"  :
#                command => "/opt/xcat/sbin/makedns -n",
#                refreshonly => "true",
#        }

        Exec["makehosts"] <~ Vclmgmt::Compute_node <| |>
        Exec["makehosts"] <~ Vclmgmt::Xcat_pod <| |>
	
	Yumrepo <| tag == "vclrepo" or tag == "xcatrepo" |> -> Package <| tag == "vclinstall" |> -> Vcsrepo[ 'vcl'] ~> Vclmgmt::Cpan <| |>
    	Archive ["dojo-release-${dojo}"] -> File <| tag == "vclpostfiles" and tag != "postcopy" |> -> Vclmgmt::Vclcopy <| |> -> File <| tag == "postcopy" |> -> Mysql::Db[$vcldb] -> Exec['genkeys'] -> Service <| name == $vclmgmt::params::service_list |>
    
    	File['vcldconf'] ~> Service['vcld']
    	Vcsrepo['vcl'] ~> Vclmgmt::Vclcopy <| |>
    
	Class['mysql::server']-> Mysql::Db[$vcldb]
	Package <| tag == "vclinstall" or tag == "xcatpkg" |> -> Xcat_site_attribute <| |> ~> Service['xcatd']

	Package <| tag == "vclinstall" or tag == "xcatpkg" |> -> Xcat_network <| |> -> Xcat_node<| |>
	Xcat_network <| ensure == absent |> -> Xcat_network <| ensure != absent |>
	Archive[ "dojo-release-${dojo}" ] ~> Vclmgmt::Regexfile <| |>
}
