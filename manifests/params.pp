class vclmgmt::params {

	$vcldir          = '/vcl'
	$dojo            = '1.6.2'
#	$vclweb          = '/var/www/html/vcl'
	$vclnode         = '/usr/local/vcl'
	
	# defaults
	$configfile = {
		ensure  => file,
		mode    => '0644',
		tag 	=> "vclpostfiles",
  }
    
  $servicedefault = {
    ensure => running,
    hasstatus => true,
    hasrestart => true,
    enable => true,
  }
    
  case $::osfamily {

    'RedHat': {
        
	    $fedora_base      = "http://dl.fedoraproject.org/pub/epel"
	    $key      = '/repodata/repomd.xml.key'
	    $defaultrepo = {
	      enabled  => 1,
	      gpgcheck => 1,
        tag   => "vclrepo",
      }
      $repos = {
        'fedoraproject' => {
          descr  => 'dl.fedoraproject.org epel mirror',
          baseurl => "${fedora_base}/${lsbmajdistrelease}/${architecture}",
          gpgkey  => "${fedora_base}/RPM-GPG-KEY-EPEL-${lsbmajdistrelease}",
        },
      }
        
      $pkg_list = [ 
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
        "expat-devel", 
        "gcc", 
        "java-1.7.0-openjdk",
        "krb5-libs", 
        "krb5-devel", 
        "libxml2-devel", 
        "make", 
        "nmap", 
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
        "subversion",
        "git",
      ]
      $pkg_exclude = [ ]
      $service_list = {  
        "vcld"   => {},
      }
    }

    default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  $cpan_list = [ 
	  "CPAN", 
	  "DBI", 
	  "Scalar::Util", 
	  "Digest::SHA1", 
	  "LWP::Protocol::https", 
	  "Mail::Mailer", 
	  "Mo::builder", 
	  "Object::InsideOut", 
	  "RPC::XML", 
	  "URI", 
	  "YAML" 
  ]

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
