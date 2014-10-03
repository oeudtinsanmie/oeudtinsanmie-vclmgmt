include stdlib

# Class: vclmgmt
#
# This module installs VCL and manages its database and xCAT resources.  
# Base class sets up the xcat site table, and initializes the three network interfaces used by VCL
# If hashes are provided for public-private-ipmi network tuples (pods) and their constituent computers, 
# relevant information from the installation is propagated as default values to resource declarations of these constituent resources
#
# Parameters:
# [*public_mac*] 
#   - MAC address for public-network facing interface
# [*public_if*] 
#   - Interface name of public-network facing interface.
#     Defaults to 'em1'
# [*public_ip*] 
#   - IP address for public-network facing interface 
#     Defaults to 'dhcp' 
# [*private_mac*] 
#   - MAC address for private-network facing interface (network for provisioning target computers)
# [*private_if*]
#   - Interface name of private-network facing interface (network for provisioning target computers) 
#     Defaults to 'em2'
# [*private_ip*] 
#   - IP address for private-network facing interface (network for provisioning target computers) 
# [*private_domain*]
#   - Domain for private-network facing interface (network for provisioning target computers) 
# [*ipmi_mac*] 
#   - MAC address for ipmi-network facing interface (connected to DRACs of target computers)
# [*ipmi_if*] 
#   - Interface name of ipmi-network facing interface (connected to DRACs of target computers)
#     Defaults to 'p4p1'
# [*ipmi_ip*] 
#   - IP address for ipmi-network facing interface (connected to DRACs of target computers)
# [*vcldb*] 
#   - Database used by vcl
#     Defaults to 'vcl' 
# [*vcluser*] 
#   - Database user for vcl
#     Defaults to 'vcluser' 
# [*root_pw*]
#   - Database root password 
# [*vcluser_pw*] 
#   - Database vcl user password
# [*system_user*] 
#   - Admin account used in provisioned computers
#     Defaults to 'root'
# [*system_pw*]
#   - Password for root accout in provisioned computers
# [*vclhost*] 
#   - Address of vcl webface
#     Defaults to 'localhost' 
# [*serverip*] 
#   - Address of vcl database
#     Defaults to 'localhost' 
# [*xmlrpc_user*] 
#   - xmlrpc_username must be the unityid field for a user in the user table
#     Required for block reservation processing
#     Defaults to 'admin' 
# [*xmlrpc_pw*] 
#   - Password for xmlrpc_user
#     This parameter does not set the password.  It only fills out the vcld configuration file
#     Defaults to 'just_another_password'
# [*xmlrpc_url*] 
#   - the URL will be the URL of your VCL website with a few things on the end
#     for example, if you install the VCL web code at https://vcl.example.org/vcl/
#     set xmlrpc_url to https://vcl.example.org/vcl/index.php?mode=xmlrpccall
#     Defaults to "https://$fqdn/vcl/index.php?mode=xmlrpccall"
# [*poddefaults*] 
#   - Default values applied to pod hashes supplied in the class definition
#     pod values take precedence over poddefaults, which take precedence over defaults derived from the management node definition
#     Defaults to empty set
# [*pods*] 
#   - Hashes defining public/private/ipmi tuples (pods) supported by this management node.  If not undef, these hashes will be populated with default values from the management node and declared as puppet resources 
#     Defaults to undef
# [*vcldir*] 
#   - Directory in which to place vcl svn repo 
#     Defaults to vclmgmt::params::vcldir
# [*dojo*] 
#   - Dojo version
#     Defaults to vclmgmt::params::dojo
# [*dojotheme*]
#   - dijit theme used for vcl
#     Defaults to tundra
# [*vclweb*]
#   - VCL web folder location
#     Defaults to vclmgmt::params::vclweb
# [*vclnode*]
#   - Alias within standard path for vcl directory
#     Defaults to vclmgmt::params::vclnode
# [*firewalldefaults*]
#   - Set pre and post class requirements for the firewall declarations
#     Defaults to
#      {
#        require => Class['ncsufirewall::pre'],
#        before  => Class['ncsufirewall::post'],
#      }
# [*vclversion*]
#   - The release of vcl to pull from the repo, or "latest" if you want to work with the trunk
#     Defaults to release-2.3.2-RC2
# [*vclrevision*]
#   - If defined, pulls a specific revision of the vcl subversion repo
#     Defaults to undefined
# [*usexcat*]
#   - Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers
#     Defaults to false
#     
class vclmgmt(
  $public_mac, 
  $public_if     = 'em1', 
  $public_ip     = 'dhcp', 
  $private_mac,
  $private_if    = 'em2', 
  $private_ip,  
  $private_domain, 
  $ipmi_mac,
  $ipmi_if       = 'p4p1',  
  $ipmi_ip, 
  $vcldb         = 'vcl', 
  $vcluser       = 'vcluser', 
  $root_pw, 
  $vcluser_pw, 
  $system_user   = 'root',
  $system_pw,
  $vclhost       = 'localhost', 
  $serverip      = 'localhost', 
  $xmlrpc_pw     = 'just_another_password', 
  $xml_url       = "https://$fqdn/vcl/index.php?mode=xmlrpccall",
  $poddefaults   = {},
  $pods          = undef,
  $vcldir        = $vclmgmt::params::vcldir,
  $dojo          = $vclmgmt::params::dojo,
  $dojotheme     = "tundra",
  $vclweb        = $vclmgmt::params::vclweb,
  $vclnode       = $vclmgmt::params::vclnode,
  $firewalldefaults = {
    require => Class['ncsufirewall::pre'],
    before  => Class['ncsufirewall::post'],
  },
  $vclversion = "release-2.3.2-RC2",
  $vclrevision = undef,
  $usexcat = false,
) inherits vclmgmt::params {
  
  ############## Definitions
  $htinc = "${vclweb}/.ht-inc"
  $vclimgs = "${vcldir}/images"  
  
  $postfiles = {
    "vclweb" => {
      path => "/.vclweb",
      ensure => present,
      content => "${vcldir}/web",
      replace => false,
    },
    "vclprofile"  => {
      path => "${vcldir}/web/dojosrc/util/buildscripts/profiles/vcl.profile.js",
      ensure => present,
      content => "dependencies = { \"layers\": [], \"prefixes\": [] }",
      replace => false,
      tag  => "postcopy",      
    },
    "${vclweb}"  => {
      ensure   => "link",
      path  => "${vclweb}",
      target   => "${vcldir}/web",
    },
    "${vclnode}"  => {
      ensure   => "link",
      path  => "${vclnode}",
      target  => "${vcldir}/managementnode",
    },
    "vcldojo" => {
      ensure   => "link",
      path  => "${vclweb}/dojosrc/vcldojo",
      target  => "${vclweb}/js/vcldojo",
      tag  => "postcopy",      
    },
    "maintenance" => {
      path  => "${htinc}/maintenance",
      ensure  => "directory",
      owner   => "apache",
    },
    "vcld" => {
      path  => '/etc/init.d/vcld',
      ensure  => "present",
      mode  => "a+x",
      tag  => "postcopy",
    },
    "images" => {
      path  => $vclimgs,
      ensure   => "directory",
    },
    "etcvcl" => {
      path  => "/etc/vcl",
      ensure  => "directory",
    },
  }
  
  $vclcopyfiles = {
#   Will copy / edit this via Augeas in future versions
#   'vcldconf' => {
#     path   => "${vcldir}/managementnode/etc/vcl/vcld.conf",
#     tgtdir  => '/etc/vcl',
#     target  => 'vcld.conf',
#    }, 
    'vcld' => {
      path  => "${vcldir}/managementnode/bin/S99vcld.linux",
      tgtdir  => '/etc/init.d',
      target  => 'vcld',
    },
  }
  
  $configs = {
    'secrets' => {
      path  => "${htinc}/secrets.php",
      content  => template('vclmgmt/secrets.php.erb'),
    },
    # Remove this in future version, once copy / edit works above
    'vcldconf' => {
      path  => "/etc/vcl/vcld.conf",
      content => template('vclmgmt/vcld.conf.erb'),
    },
    'confphp' => {
      path  => "${htinc}/conf.php",
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
  }
  
  $xcatfirewalls = {
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
  
  ############# Internal Class Definitions
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
  
  define vclmgmt::dojoimport ($utils) {
    create_resources(vcldojo_layer, read_vcldojo($utils))
  }
  
  ############# Package Repositories
  case $::osfamily {
    'RedHat': {
      create_resources(yumrepo, $vclmgmt::params::repos, $vclmgmt::params::defaultrepo)
    }
    
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  ############### Packages
# todo: convert to future parser each method check, once wider support
#  each($vclmgmt::params::pkg_list) |$pkg| {
#    if ! defined(Package[$pkg]) {
#      package { $pkg:
#        ensure => "latest", 
#        provider => "yum", 
#        tag  => "vclinstall",
#      }
#    }
#    else {
#      Package <| title == $pkg |> {
#        tag => "vclinstall",
#      }
#    }
#  }
#  each($vclmgmt::params::pkg_exclude) |$pkg| {
#    if ! defined(Package[$pkg]) {
#      package { $pkg: 
#        ensure => "absent", 
#      }
#    }
#    else {
#      Package <| title == $pkg |> {
#        ensure => "absent",
#      }
#    }
#  }
# For now, pulling out individual known conflicts for checks here:
  if ! defined(Package["openssl-devel"]) {
    package {"openssl-devel":
      ensure => "latest", 
      provider => "yum", 
      tag  => "vclinstall",
    }
  }
  else {
    Package <| title == 'openssl-devel' |> {
      tag => "vclinstall",
    }
  }
  if ! defined(Package["httpd"]) {
    package {"httpd":
      ensure => "latest", 
      provider => "yum", 
      tag  => "vclinstall",
    }
  }
  else {
    Package <| title == 'httpd' |> {
      tag => "vclinstall",
    }
  }
  
  package { $vclmgmt::params::pkg_list:
    ensure => "latest", 
    provider => "yum", 
    tag   => "vclinstall",
  }
  
  package { $vclmgmt::params::pkg_exclude: 
    ensure => "absent", 
  }
  
  # use cpan to install needed modules
  vclmgmt::cpan { $vclmgmt::params::cpan_list: }
  
  ############## VCL Code
  # get requested version / revision of vcl from svn repo
  if $vclversion == latest {
    $repodir = "trunk"
  }
  else {
    $repodir = "tags/${vclversion}"
  }
  file { $vcldir :
    ensure  => "directory",
  } ->
  vcsrepo { "vcl" :
    ensure => present,
    path  => $vcldir,
    provider => svn,
    source   => "http://svn.apache.org/repos/asf/vcl/${repodir}",
  }
  
  if $vclrevision != undef {
    Vcsrepo <| title == 'vcl' |> {
      revision => $vclrevision,
    }
  }
  
  # create / link files to set up vcl as needed
  create_resources(file, $postfiles, { tag => "vclpostfiles", })
  
  # create config files
  create_resources(file, $configs, $vclmgmt::params::configfile)
  
  # copy files 
  create_resources(vclmgmt::vclcopy, $vclcopyfiles)
    
  # generate keys with genkeys script
  exec { 'genkeys' :
    command => '/bin/sh genkeys.sh',
    cwd  => $htinc,
    creates  => "${htinc}/keys.pem",
  }
  
  ########### Security
  # set up firewalls
  create_resources(firewall, $firewalls, $firewalldefaults)
    
  # if selinux is enabled, set selbooleans correctly
  if str2bool("$selinux") {
    create_resources(selboolean, $vclmgmt::params::sebools)
  }

  # declare services
  create_resources(service, $vclmgmt::params::service_list, $vclmgmt::params::servicedefault)
  
  ######## network setup  
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
  
  ############# Database
  if ! defined(Class['::mysql::server']) {
    class {'::mysql::server':
      root_password => $root_pw,
      require => Class['vclmgmt::params'],
    }
  }
  
  mysql::db { $vcldb :
    user => $vcluser,
    password => $vcluser_pw,
    host => 'localhost',
    grant => ['GRANT', 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TEMPORARY TABLES'],
    sql => "${vclmgmt::params::vcldir}/mysql/vcl.sql",
  }

  ############## Dojo
  vclmgmt::dojoimport { "dojo-layers" :
    utils => "${htinc}/utils.php",
  }

  $vclprefixes = {
    "dojo" => {
      path => "../../dojo",
    },
    "dojox" => {
      path => "../dojox",
    },
    "dijit" => {
      path => "../dijit",
    },
    "vcldojo" => {
      path => "../vcldojo",
    },
  }
  create_resources(vcldojo_prefix, $vclprefixes)
  
  file { "dojosrc":
    path => "${vcldir}/web/dojosrc",
    ensure => "directory",
  } 
  vcsrepo { "dojo" :
    ensure => present,
    path  => "${vcldir}/web/dojosrc/dojo",
    provider => git,
    source   => "https://github.com/dojo/dojo.git",
    revision => $dojo,
    tag => 'dojo',
  } 
  vcsrepo { "dojox" :
    ensure => present,
    path  => "${vcldir}/web/dojosrc/dojox",
    provider => git,
    source   => "https://github.com/dojo/dojox.git",
    revision => $dojo,
    tag => 'dojo',
  } 
  vcsrepo { "dijit" :
    ensure => present,
    path  => "${vcldir}/web/dojosrc/dijit",
    provider => git,
    source   => "https://github.com/dojo/dijit.git",
    revision => $dojo,
    tag => 'dojo',
  } 
  vcsrepo { "dojo-util" :
    ensure => present,
    path  => "${vcldir}/web/dojosrc/util",
    provider => git,
    source   => "https://github.com/dojo/util.git",
    revision => $dojo,
    tag => 'dojo',
  } 
  
  exec { "dojobuild":
    command => "/bin/sh build.sh profile=vcl action=release version=1.6.2.vcl localeList=en-us,en-gb,es-es,es-mx,ja-jp,zh-cn",
    cwd => "${vcldir}/web/dojosrc/util/buildscripts",
    refreshonly => "true",
  }
  
  $dojo_files = {
    "dojo-release" => {
	    ensure => "link",
	    path => "${vcldir}/web/dojo",
	    target => "${vcldir}/web/dojosrc/release/dojo/",
	  },
    "dojo-theme" => {
      path => "${vcldir}/web/themes/default/css/dojo",
      ensure => "link",
      target => "${vcldir}/web/dojosrc/release/dojo/dijit/themes/${dojotheme}",
    },
    "dojo-theme-css" => {
      path => "${vcldir}/web/dojosrc/release/dojo/dijit/themes/${dojotheme}/default.css",
      ensure => "link",
      target => "${vcldir}/web/dojosrc/release/dojo/dijit/themes/${dojotheme}/${dojotheme}.css",
    },
    "dijit-css" => {
      path => "${vcldir}/web/themes/default/css/dijit.css",
      ensure => "link",
      target => "${vcldir}/web/dojosrc/release/dojo/dijit/themes/dijit.css",
    },
    "dijit-icons" => {
      path => "${vcldir}/web/themes/default/icons",
      ensure => "link",
      target => "${vcldir}/web/dojosrc/release/dojo/dijit/icons",
    },
  }
  
  create_resources(file, $dojo_files, { tag => "dojo", })
  
  ############### xCAT
  # setup xcat, if it's being used
  if $usexcat == true {
    class { "xcat": }
    
    create_resources(firewall, $xcatfirewalls, $firewalldefaults)
    
    $privatenet = split($private_ip, '\.')
    xcat_network { "${privatenet[0]}_${privatenet[1]}_${privatenet[2]}_0-255_255_255_0":
      ensure => absent,
    }
    $ipminet = split($ipmi_ip, '\.')
    xcat_network { "${ipminet[0]}_${ipminet[1]}_${ipminet[2]}_0-255_255_255_0":
      ensure => absent,
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
    
    xcat_site_attribute  { "xcatprefix" :
      sitename => 'clustersite',
      value => "/opt/xcat",
    }  
    
    exec { "makehosts" :
      command => "/opt/xcat/sbin/makehosts",
      refreshonly => "true",
    }~>
    exec { "rmleases":
      command => "rm -rf /var/lib/dhcpd/dhcpd.leases",
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
  
    # Chain declarations for xcat resources
    Exec["makehosts"] <~ Vclmgmt::Compute_node <| |>
    Exec["makehosts"] <~ Vclmgmt::Xcat_pod <| |>
    Exec["makedns"] ~> Service["xcatd"] ~> Service["vcld"]
      
  }
  
  ################ Pods
  # declare any pods included in class declaration
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
      usexcat => $usexcat,
    }
    $newpods = set_defaults($pods, $poddefaults, $masterdefault)
    create_resources(vclmgmt::xcat_pod, $newpods)
  }

  ############# Resource Chains
  # Chain declarations for vclmgmt resources
  Yumrepo <| tag == "vclrepo" or tag == "xcatrepo" |> -> Package <| tag == "vclinstall" |> -> Vcsrepo['vcl']
  File <| tag == "vclpostfiles" and tag != "postcopy" |> -> Vclmgmt::Vclcopy <| |>      -> File <| tag == "postcopy" |> -> Mysql::Db[$vcldb] -> Exec['genkeys']  
  File <| tag == "vclpostfiles" and tag != "postcopy" |> -> Vcsrepo <| tag == 'dojo' |> -> File <| tag == "postcopy" |> -> Vclmgmt::Dojoimport <| |>

  File ["vclweb"] -> File ["vclprofile"]
  File ["vclprofile"] -> Vcldojo_prefix <| |>        ~> Exec["dojobuild"]
  File ["vclprofile"] -> Vcldojo_layer  <| |>        ~> Exec["dojobuild"]
  File ["dojosrc"]    -> Vcsrepo <| tag == 'dojo' |> ~> Exec["dojobuild"]
  Exec["dojobuild"] -> File <| tag == "dojo" |>
  
  File['vcldconf'] ~> Service['vcld']
  Vcsrepo['vcl'] ~> Vclmgmt::Vclcopy <| |>
  Vcsrepo['vcl'] ~> Vclmgmt::Cpan <| |>

  Class['mysql::server']-> Mysql::Db[$vcldb]
  Mysql::Db[$vcldb] -> Vcl_computer <| |>
  Mysql::Db[$vcldb] -> Vcl_image <| |>
  
  Class['vclmgmt'] -> Vclmgmt::Baseimage <| |>
  Class['vclmgmt'] -> Service <| name == $vclmgmt::params::service_list |>
}
