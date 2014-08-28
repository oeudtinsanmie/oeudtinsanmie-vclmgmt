class vclmgmt::params {

    $vcldir 	= hiera('vclmgmt::vcldir', '/vcl')
    
    $dojo	= hiera('vclmgmt::dojo', '1.10.0')

    $vclweb 	= hiera('vclmgmt::vclweb', '/var/www/html/vcl')
    $vclnode 	= hiera('vclmgmt::vclnode', '/usr/local/vcl')
    $vclimages	= hiera('vclmgmt::vclimages', "${vcldir}/images")

    $htinc = "${vclweb}/.ht-inc"
    
    $archives = {
        "dojo-release-${vclmgmt::params::dojo}" => {
		url	=> "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${vclmgmt::params::dojo}.tar.gz",
		target	=> "${vcldir}/web/",
	},
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
    		target 	=> "${vclweb}/dojo-release-${vclmgmt::params::dojo}",
    	},
    	"${vclweb}/dojo/vcldojo" => {
        	ensure 	=> "link",
    		path	=> "${vclweb}/dojo/vcldojo",
    		target	=> "${vclweb}/js/vcldojo",
    	},
    	"maintenance" => {
		path	=> "${vclmgmt::params::htinc}/maintenance",
		ensure  => "directory",
		owner   => "apache",
	},
	"vcld" => {
		path	=> $vclmgmt::params::vclcptargets[$vclmgmt::params::vcld],
		ensure	=> "present",
		mode	=> "a+x",
	},
	"images" => {
		path	=> $vclmgmt::params::vclimages,
		ensure 	=> "directory",
	}
    }
    
    $vclcopyfiles = {
# Will copy / edit this via Augeas in future versions
#    	'vcldconf' => {
#    		path 	=> "${vcldir}/managementnode/etc/vcl/vcld.conf",
#    		tgtdir	=> '/etc/vcl',
#    		target	=> 'vcld.conf',
#    	}, 
    	'vcld' => {
    		path	=> "${vcldir}/managementnode/bin/S99vcld.linux",
    		tgtdir	=> '/etc/init.d',
    		target	=> 'vcld',
    	},
    }
    
    $configs = {
    	'secrets' => {
    		path	=> "${vclmgmt::params::htinc}/secrets.php",
		content	=> template('vclmgmt/secrets.php.erb'),
	},
	# Remove this in future version, once copy / edit works above
	'vcldconf' => {
		path	=> "/etc/vcl/vcld.conf",
		content => template('vclmgmt/vcld.conf.erb'),
	},
	'confphp' => {
		path	=> "${vclmgmt::params::htinc}/conf.php",
		content => template('vclmgmt/conf.php.erb'),
	},
    }
    
    # defaults
    $webarchive = {
	ensure 	=> present,
    	timeout => 0,
    }
    
    $configfile = {
	ensure 	=> file,
	mode	=> '0644',
    }
    
    case $::osfamily {

    	'RedHat': {
    		
            	$fedora_base   	 = "http://dl.fedoraproject.org/pub/epel"
            	$xcatcore_mirror = 'http://sourceforge.net/projects/xcat/files/yum/2.8/xcat-core'
            	$xcatdep_mirror  = "http://sourceforge.net/projects/xcat/files/yum/xcat-dep/rh${lsbmajdistrelease}/${architecture}"
            	$centos_mirror   = "http://ftp.linux.ncsu.edu/pub/CentOS/${lsbmajdistrelease}/os/${architecture}"
            	$key 		 = '/repodata/repomd.xml.key'
            	$defaultrepo = {
            		enabled  => 1,
            		gpgcheck => 1,
            	}
    		$repos = {
    			'xcat-2-core' => {
    				descr	=> 'xCat 2 Core packages',
    				baseurl => $xcatcore_mirror,
    				gpgkey	=> "${xcatcore_mirror}${key}",
    			},
    			'xcat-dep' => {
    				descr	=> 'xCat 2 Core dependencies',
    				baseurl => $xcatdep_mirror,
    				gpgkey	=> "${xcatdep_mirror}${key}",
    			},
    			'centos' => {
    				descr	=> 'NCSU CentOS Mirror',
    				baseurl => $centos_mirror,
    				gpgkey	=> "${centos_mirror}/RPM-GPG-KEY-CentOS-${lsbmajdistrelease}",
    			},
    			'fedoraproject' => {
    				descr	=> 'dl.fedoraproject.org epel mirror',
    				baseurl => "${fedora_base}/${lsbmajdistrelease}/${architecture}",
    				gpgkey	=> "${fedora_base}/RPM-GPG-KEY-EPEL-${lsbmajdistrelease}",
    			},
    		}
    		
    		$pkg_list = [ 
    			"httpd", 
    			"mod_ssl", 
    			"php", 
    			"php-gd", 
    			"php-mcrypt", 
    			"php-mysql", 
    			"php-xml", 
    			"php-xmlrpc", 
    			"php-ldap", 
    			"php-process", 
    			"augeas", 
    			"phpMyAdmin.noarch", 
    			"subversion", 
    			"expat-devel", 
    			"gcc", 
    			"krb5-libs", 
    			"krb5-devel", 
    			"libxml2-devel", 
    			"make", 
    			"nmap", 
    			"openssl-devel", 
    			"perl-Archive-Tar", 
    			"perl-CPAN", 
    			"perl-Crypt-OpenSSL-RSA", 
    			"perl-DBD-MySQL", 
    			"perl-DBI", 
    			"perl-Digest-SHA1", 
    			"perl-IO-String", 
    			"perl-MailTools", 
    			"perl-Net-Jabber", 
    			"perl-Net-Netmask", 
    			"perl-Net-SSH-Expect", 
    			"perl-Text-CSV_XS", 
    			"perl-XML-Simple", 
    			"perl-YAML", 
    			"xmlsec1-openssl",
    		]
            	$pkg_exclude = [ ]
            	$service_list = [ 
            		"xinetd", 
            		"httpd", 
            		"vcld",
            		"ipmi",
            	]
    	}

    	default: {
      		fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    	}
    }

    $cpan_list = [ "CPAN", "DBI", "Scalar::Util", "Digest::SHA1", "LWP::Protocol::https", "Mail::Mailer", "Mo::builder", "Object::InsideOut", "RPC::XML", "URI", "YAML" ]

    $firedefaults = {
    	require => Class['ncsufirewall::pre'],
	before  => Class['ncsufirewall::post'],
    }
    $firewalls = {
    	'100 accept http' => {
	        chain => 'INPUT',
	        proto => 'tcp',
	        action=> 'accept',
	        dport => 80,
	        state => 'NEW',
	},
	'105 accept https' => {
	        chain => 'INPUT',
	        proto => 'tcp',
	        action=> 'accept',
	        dport => 443,
	        state => 'NEW',
	},
	'112 reject foward across vlans' => {
		chain => 'FORWARD',
		proto => 'all',
		action => 'reject',
	},
    }
    
    $sebools = {
    	'httpd can connect' => {
	        name => 'httpd_can_network_connect',
	        persistent => true,
	        value => 'on',
	},
    }
}
