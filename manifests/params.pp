class vclmgmt::params {
    $vcldir = '/vcl'
    $maintenance = "${vcldir}/web/.ht-inc/maintenance"

    $xcatcore = 'xcat-2-core'
    $xcatdep  = 'xcat-dep'
    $xcatcore_desc = 'xCat 2 Core packages'
    $xcatdep_desc  = 'xCat 2 Core dependencies'
    case $operatingsystem {
        /(RedHat|CentOS|Fedora)/: {
            $xcatcore_mirror = 'http://xcat.sourceforge.net/yum/2.6/xcat-core'
            $xcatdep_mirror = 'http://xcat.sourceforge.net/yum/xcat-dep/rh\$lsbmajdistrelease/\$basearch'
            $key = '/repodata/repomd.xml.key'
            $xcatcore_key = "${xcatcore_mirror}${key}"
            $xcatdep_key = "${xcatdep_mirror}${key}"

            $pkg_list = [ "mysql-server", "httpd", "mod_ssl", "php", "php-gd", "php-mcrypt", "php-mysql", "php-xml", "php-xmlrpc", "php-ldap", "php-sysvsem", "augeas", "phpMyAdmin.noarch", "dhcp" ]
            $tftp  = "tftp-server"
            $atftp = "atftp-xcat"
            if $basearch == 'x86_64' {
                $tftp  = "${tftp}.x86_64"
                $atftp = "${atftp}.x86_64"
            }
            $pkg_list += $tftp
            $pkg_list += "xCat"
            $pkg_exclude = [ $atftp ]

            $service_list = [ "network", "dhcpd", "xinetd", "mysqld", "htpd", "vcld" ]
        }
    }
}
