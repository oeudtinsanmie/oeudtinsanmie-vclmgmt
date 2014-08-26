class vclmgmt::params {

    $vcldir 	= hiera('vclmgmt::vcldir', '/vcl')
    
    $dojo	= hiera('vclmgmt::dojo', '1.10.0')

    $vclweb 	= hiera('vclmgmt::vclweb', '/var/www/html/vcl')
    $vclnode 	= hiera('vclmgmt::vclnode', '/usr/local/vcl')
    $vclimages	= hiera('vclmgmt::vclimages', "${vcldir}/images")
    
    $vcllinks = [ $vclweb, $vclnode ]
    $vcllinktargets = {
        "${vclweb}"	=>	"${vcldir}/web",
        "${vclnode}"	=>	"${vcldir}/managementnode",
    }

    $vcldconf 	= "${vcldir}/managementnode/etc/vcl/vcld.conf"
    $vcld	= "${vcldir}/managementnode/bin/S99vcld.linux"
	
    $vclcopyfiles = [ $vcldconf, $vcld ]

    $vclcptgtdirs = {
	"${vcldconf}"	=> '/etc/vcl',
	"${vcld}"	=> '/etc/init.d',
    }

    $vclcptargets = {
	"${vcldconf}"	=> '/etc/vcl/vcld.conf',
	"${vcld}"	=> '/etc/init.d/vcld',
    }

    $htinc = "${vclweb}/.ht-inc"

    $xcatcore = 'xcat-2-core'
    $xcatdep  = 'xcat-dep'
    $centos   = 'centos'
    $fedora   = 'fedoraproject'

    $xcatcore_desc = 'xCat 2 Core packages'
    $xcatdep_desc  = 'xCat 2 Core dependencies'
    $centos_desc  = 'NCSU CentOS Mirror'
    $fedora_desc  = 'dl.fedoraproject.org epel mirror'

#    case $operatingsystem {
#        /(RedHat|CentOS|Fedora)/: {
            $xcatcore_mirror = 'http://sourceforge.net/projects/xcat/files/yum/2.8/xcat-core'
            $xcatdep_mirror  = "http://sourceforge.net/projects/xcat/files/yum/xcat-dep/rh${lsbmajdistrelease}/${architecture}"
            $centos_mirror   = "http://ftp.linux.ncsu.edu/pub/CentOS/${lsbmajdistrelease}/os/${architecture}"
            $fedora_base   = "http://dl.fedoraproject.org/pub/epel"
            $fedora_mirror   = "${fedora_base}/${lsbmajdistrelease}/${architecture}"
            $key = '/repodata/repomd.xml.key'
            $xcatcore_key = "${xcatcore_mirror}${key}"
            $xcatdep_key = "${xcatdep_mirror}${key}"
            $centos_key = "${centos_mirror}/RPM-GPG-KEY-CentOS-${lsbmajdistrelease}"
            $fedora_key = "${fedora_base}/RPM-GPG-KEY-EPEL-${lsbmajdistrelease}"

			# "mysql-server", 
            $pkg_list = [ "httpd", "mod_ssl", "php", "php-gd", "php-mcrypt", "php-mysql", "php-xml", "php-xmlrpc", "php-ldap", "php-process", "augeas", "phpMyAdmin.noarch", "subversion", "expat-devel", "gcc", "krb5-libs", "krb5-devel", "libxml2-devel", "make", "nmap", "openssl-devel", "perl-Archive-Tar", "perl-CPAN", "perl-Crypt-OpenSSL-RSA", "perl-DBD-MySQL", "perl-DBI", "perl-Digest-SHA1", "perl-IO-String", "perl-MailTools", "perl-Net-Jabber", "perl-Net-Netmask", "perl-Net-SSH-Expect", "perl-Text-CSV_XS", "perl-XML-Simple", "perl-YAML", "xmlsec1-openssl" ]

            $pkg_exclude = [ ]
            $service_list = [ "xinetd", "httpd", "vcld" ]
#        }
#    }

    $cpan_command = "/usr/bin/cpanp -i --skiptest"
    $cpan_list = [ "CPAN", "DBI", "Scalar::Util", "Digest::SHA1", "LWP::Protocol::https", "Mail::Mailer", "Mo::builder", "Object::InsideOut", "RPC::XML", "URI", "YAML" ]

    
}
