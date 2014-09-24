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
# [*ipmi_ip*] 
#   - IP address for ipmi-network facing interface (connected to DRACs of target computers)
# [*ipmi_if*] 
#   - Interface name of ipmi-network facing interface (connected to DRACs of target computers)
#     Defaults to 'p4p1'
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
# [*dojo_checksum*]
#   - Whether to look for an MD5 Checksum for dojo archive
#     Defaults to vclmgmt::params::dojo_checksum
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
  $ipmi_ip, 
  $ipmi_if       = 'p4p1', 
  $vcldb         = 'vcl', 
  $vcluser       = 'vcluser', 
  $root_pw, 
  $vcluser_pw, 
  $system_user   = 'root',
  $system_pw,
  $vclhost       = 'localhost', 
  $serverip      = 'localhost', 
  $xmlrpc_pw     = 'just_another_password', 
  $xml_url       = 'localhost',
  $poddefaults   = {},
  $pods          = undef,
  $vcldir        = $vclmgmt::params::vcldir,
  $dojo          = $vclmgmt::params::dojo,
  $dojo_checksum = $vclmgmt::params::dojo_checksum,
  $vclweb        = $vclmgmt::params::vclweb,
  $vclnode       = $vclmgmt::params::vclnode,
  $firewalldefaults = {
    require => Class['ncsufirewall::pre'],
    before  => Class['ncsufirewall::post'],
  },
  $vclversion = "release-2.3.2-RC2",
  $vclrevision = undef,
) inherits vclmgmt::params {

  class { "xcat": }
  if ! defined(Class['apache']) {
    class { "apache": }
  }
  Package <| title == 'apache' |> {
    tag => "vclinstall",
  }

  $htinc = "${vclweb}/.ht-inc"
  $vclimgs = "${vcldir}/images"  
  
  $postfiles = {
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
    "${vclweb}/dojo" => {
      ensure   => "link",
      path  => "${vclweb}/dojo",
      target   => "${vclweb}/dojo-release-${dojo}",
    },
    "${vclweb}/dojo/vcldojo" => {
      ensure   => "link",
      path  => "${vclweb}/dojo/vcldojo",
      target  => "${vclweb}/js/vcldojo",
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
  package { $vclmgmt::params::pkg_list:
    ensure => "latest", 
    provider => "yum", 
    tag   => "vclinstall",
  }
  package { $vclmgmt::params::pkg_exclude: 
    ensure => "absent", 
  }
  
  vclmgmt::cpan { $vclmgmt::params::cpan_list: }

  # These files really should be served somewhere from the VCL project
  # Temporary workarounds:
  define vclmgmt::regexfile ($root, $tgt) {
    file { $name :
      source   => "puppet:///modules/vclmgmt/${tgt}/${name}",
      path  => "${root}/${tgt}/${name}",
    }     
  }
  
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
  } ->
  archive { "dojo-release-${dojo}" :
    url  => "http://download.dojotoolkit.org/release-${vclmgmt::params::dojo}/dojo-release-${dojo}.tar.gz",
    target  => "${vcldir}/web/",
    ensure   => present,
    timeout => 0,
    checksum=> $dojo_checksum,
  } 
  
  if $vclrevision != undef {
    Vcsrepo <| title == 'vcl' |> {
      revision => $vclrevision,
    }
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
    cwd  => $htinc,
    creates  => "${htinc}/keys.pem",
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
  } #~>   # Put this back in once xcat-generated network configuration is working. Then, remove dhcp and bind module usage  
#  exec { "makedhcpn" :
#    command => "/opt/xcat/sbin/makedhcp -n",
#    refreshonly => "true",
#  }~>
#  exec { "makedhcpa" :
#    command => "/opt/xcat/sbin/makedhcp -a",
#    refreshonly => "true",
#  }~>
#  exec { "makedns"  :
#    command => "/opt/xcat/sbin/makedns -n",
#    refreshonly => "true",
#  }

  # Chain declarations for vclmgmt resources
  Exec["makehosts"] <~ Vclmgmt::Compute_node <| |>
  Exec["makehosts"] <~ Vclmgmt::Xcat_pod <| |>

  Yumrepo <| tag == "vclrepo" or tag == "xcatrepo" |> -> Package <| tag == "vclinstall" |> -> Vcsrepo[ 'vcl'] ~> Vclmgmt::Cpan <| |>
  Archive ["dojo-release-${dojo}"] -> File <| tag == "vclpostfiles" and tag != "postcopy" |> -> Vclmgmt::Vclcopy <| |> -> File <| tag == "postcopy" |> -> Mysql::Db[$vcldb] -> Exec['genkeys'] -> Service <| name == $vclmgmt::params::service_list |>

  File['vcldconf'] ~> Service['vcld']
  Vcsrepo['vcl'] ~> Vclmgmt::Vclcopy <| |>

  Class['mysql::server']-> Mysql::Db[$vcldb]
  Mysql::Db[$vcldb] -> Vcl_computer <| |>
  Mysql::Db[$vcldb] -> Vcl_image <| |>
  Package <| tag == "vclinstall" or tag == "xcatpkg" |> -> Xcat_site_attribute <| |> ~> Service['xcatd']

  Package <| tag == "vclinstall" or tag == "xcatpkg" |> -> Xcat_network <| |> -> Xcat_node<| |>
  Xcat_network <| ensure == absent |> -> Xcat_network <| ensure != absent |>
  Archive[ "dojo-release-${dojo}" ] ~> Vclmgmt::Regexfile <| |>
}
