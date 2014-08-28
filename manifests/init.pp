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
	$vclhost 	= 'localhost', 
	$serverip 	= 'localhost', 
	$xmlrpc_pw 	= 'just_another_password', 
	$xml_url 	= 'localhost',
	$pods 		= undef,
    	$vcldir 	= $vclmgmt::params::vcldir,
    	$dojo		= $vclmgmt::params::dojo,
    	$vclweb 	= $vclmgmt::params::$vclweb,
    	$vclnode 	= $vclmgmt::params::$vclnode,
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
	
	# defaults
	$configfile = {
		ensure 	=> file,
		mode	=> '0644',
	}
	
	$servicedefault = {
	        ensure => running,
	        hasstatus => true,
	        hasrestart => true,
	        enable => true,
	}
	
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
	
	create_resources(file, $postfiles)
	
	create_resources(file, $configs, $configfile)
	
	create_resources(vclmgmt::vclcopy, $vclcopyfiles)
    
	exec { 'genkeys' :
		command => '/bin/sh genkeys.sh',
		cwd	=> $htinc,
		creates	=> "${htinc}/keys.pem",
    	}
    
    	create_resources(firewall, $vclmgmt::params::firewalls, $vclmgmt::params::firedefaults)
    
    	if str2bool("$selinux") {
    		create_resources(selboolean, $vclmgmt::params::sebools)
    	}

    	create_resources(service, $vclmgmt::params::service_list, $vclmgmt::params::servicedefault)
    
    	if $pods == undef {
		$dhcpinterfaces = [ $private_if, $ipmi_if ]
	}
	else {
		/* // Puppet 3 syntax:
		$dhcpinterfaces = $pods.map |$key, $val| { 
					[ 
					"${private_if}.${val[private_hash][vlanid]}", 
					"${ipmi_if}.${val[ipmi_hash][vlanid]}", 
					] 
				}
		$dhcpinterfaces = unique(flatten($dhcpinterfaces))
		if member($dhcpinterfaces, "${private_if}.") {
			$dhcpinterfaces = flatten( [ $private_if ], delete($dhcpinterfaces, "${private_if}."))
		}
		if member($dhcpinterfaces, "${ipmi_if}.") {
			$dhcpinterfaces = flatten( [ $ipmi_if ], delete($dhcpinterfaces, "${ipmi_if}."))
		}
		*/
		# defined a custom function to replace this for Puppet 2.7
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

    	firewall { '110 accept forward from me across bridges' :
        	chain => 'FORWARD',
        	proto => 'all',
        	action => 'accept',
		source => $private_ip,
    	}

    	firewall { "115 accept tftp" :
        	chain => 'INPUT',
        	proto => 'udp',
        	dport => 69,
        	action => 'accept',
        	destination => $private_ip,
    	}

        firewall { "116 accept sending tftp" :
                chain => 'INPUT',
                proto => 'udp',
                dport => 69,
                action => 'accept',
                source => $private_ip,
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
		require => Class['vclmgmt::subversion'],
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

	class { 'dhcp::server':
        #	opts => ['domain-name "toto.ltd"',
        #               'domain-name-servers 192.168.21.1'],                      
        }

	include bind

	if $pods != undef {
		/* // Puppet 3 syntax:
		$pods.each | $key, $val | {
			$val = merge($val, { 
				$private_hash => merge({
					master_if => $private_if,
					master_ip => $private_ip,
					master_mac => $private_mac,
				}, $val[private_hash]),
				$ipmi_hash => merge({
					master_if => $ipmi_if,
					master_ip => $ipmi_ip,
					master_mac => $ipmi_mac,
				}, $val[ipmi_hash]), 
			})
			ensure_resource(vclmgmt::xcat_pod, $key, $val)
		}
		*/
		# defined a custom function to replace this for Puppet 2.7
		$newpods = set_defaults($pods, $private_if, $private_ip, $private_mac, $ipmi_if, $ipmi_ip, $ipmi_mac)
		create_resources(vclmgmt::xcat_pod, $newpods)
	}
	
	Yumrepo <| |> -> Package <| |> -> Vclmgmt::Cpan <| |> -> Subversion::Checkout <| |> 
    	Archive ["dojo-release-${dojo}"] -> File <| name != $vcldir |> -> Vclmgmt::Copy <| |> -> Exec['genkeys'] -> Service <| |>
    
    	File['vcldconf'] ~> Service['vcld']
    	Subversion::Checkout['vcl'] ~> Vclmgmt::Copy <| |>
    
	Class['mysql::server']->Mysql::Db[$vcldb]
	Package<| |> -> Xcat_site_attribute <| |> ~> Service['xcatd']
}
