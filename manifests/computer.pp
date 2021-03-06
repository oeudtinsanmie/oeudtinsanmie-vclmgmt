include stdlib
# Class: vclmgmt::computer
#
# This class defines related vcl_computer and xcat_node objects for a provision controlled computer
#
# Parameters:
# [*ensure*] 
#   - Passthrough for ensurable objects in this class
#     Defaults to present
# [*hostname*] 
#   - Allows names of objects to be different from title of this resource
#     Defaults to $title
# [*public_ip*] 
#   - IP address for this computer on the public network
# [*public_mac*] 
#   - MAC address of this computer's interface on the public network 
# [*private_ip*] 
#   - IP address for this computer on the private network (serves images, and is boot interface)  
# [*private_mac*] 
#   - MAC address of this computer's interface on the private network (serves images, and is boot interface)
# [*private_if*] 
#   - Name of this computer's interface on the private network (serves images, and is boot interface) 
# [*ipmi_ip*] 
#   - IP address for this computer on the ipmi network (connects to the DRAC ports of provisioned computers)
# [*ipmi_mac*] 
#   - MAC address for this computer on the ipmi network (connects to the DRAC ports of provisioned computers)
# [*ipmi_user*] 
#   - Username for ipmi on target node
# [*ipmi_pw*] 
#   - Password for ipmi on target node
# [*master_ip*] 
#   - IP Address of management node (For the private network interface, not its vlan alias)
# [*xcat_groups*] 
#   - Groups to add this computer to within xCAT
#     Defaults to [ 'ipmi', 'compute', 'all' ]
# [*vcl_groups*] 
#   - Groups to add this computer to within VCL
#     Defaults to [ 'allComputers' ]
# [*tgt_os*] 
#   - OS to provision this computer with
# [*tgt_arch*] 
#   - Architecture of this computer
#     Defaults to undef
# [*profile*] 
#   - Profile to apply when provisioning this computer
# [*username*] 
#   - System username for this computer
#     Defaults to 'root'
# [*password*] 
#   - Password for that username
# [*netboot*] 
#   - Netboot method for provisioning
#     Defaults to 'pxe'
# [*provmethod*] 
#   - Provisioning method
#     Defaults to 'install'
# [*ram*] 
#   - Amount of RAM in this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*procnumber*] 
#   - Number of processors on this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*procspeed*] 
#   - Processor speed of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*network*] 
#   - Network speed of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*type*] 
#   - Type of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*drivetype*] 
#   - Type of hard drives within this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*deleted*] 
#   - Whether this computer record should be marked deleted within the database
#     Defaults to undef -> inherits defaults from vcl_computer
# [*notes*] 
#   - Notes for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*location*] 
#   - Physical location of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*dsa*] 
#   - DSA for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*dsapub*] 
#   - Public DSA for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*rsa*] 
#   - RSA for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*rsapub*] 
#   - Public RSA for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*hostpub*] 
#   - Host's public signature
#     Defaults to undef -> inherits defaults from vcl_computer
# [*platform*] 
#   - Platform of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*vclschedule*] 
#   - Schedule to assign this computer within VCL
#     Defaults to undef -> inherits defaults from vcl_computer
# [*image*] 
#   - Image to assign this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*imagerevision*] 
#   - Image revision to assign this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*provisioning*] 
#   - Provisioning method for this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*vmhost*] 
#   - VM Host of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*vmtype*] 
#   - VM Type of this computer
#     Defaults to undef -> inherits defaults from vcl_computer
# [*vmprofile*]
#   - VM Profile for this hypervisor.
#     Defaults to undef -> inherits defaults from vcl_computer ("none")
# [*vmlimit*]
#   - Limit of VMs to host on this hypervisor
#     Defaults to undef -> inherits defaults from vcl_computer ("none")
# [*usexcat*]
#   - Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers
#     Defaults to false
#
define vclmgmt::computer(
  $ensure       = present, 
  $hostname     = $title,
  $public_ip, 
  $public_mac,
  $private_ip, 
  $private_mac, 
  $private_if, 
  $ipmi_ip       = undef, 
  $ipmi_mac      = undef, 
  $ipmi_user     = undef, 
  $ipmi_pw       = undef, 
  $master_ip,
  $xcat_groups   = [ 'ipmi', 'compute', 'all' ],
  $vcl_groups    = [ 'allComputers' ],
  $tgt_os, 
  $tgt_arch      = undef,
  $profile,
  $username      = 'root',
  $password,
  $netboot       = 'pxe',
  $provmethod    = 'install',
  $vcl_state     = undef,
  $ram           = undef,
  $procnumber    = undef,
  $procspeed     = undef,
  $network       = undef,
  $type          = undef,
  $drivetype     = undef, 
  $deleted       = undef,       
  $notes         = undef,
  $location      = undef,
  $dsa           = undef,
  $dsapub        = undef,
  $rsa           = undef,
  $rsapub        = undef,
  $hostpub       = undef,
  $platform      = undef,
  $vclschedule   = undef,
  $image         = undef,
  $imagerevision = undef,
  $provisioning  = undef,
  $vmhost        = undef,
  $vmtype        = undef,
  $vmprofile     = undef,
  $vmlimit       = undef,
  $usexcat       = false,
  $pubvlan       = undef,
  $privlan       = undef,
  $virtpath      = undef,
) {
  if $usexcat == true {
	  xcat_node { $hostname :
	    ensure              => $ensure,
	    groups              => $xcat_groups,
	    ip                  => $private_ip,
	    mac                 => $private_mac,
	    bmc                 => "${hostname}-ipmi",
	    bmcusername         => $ipmi_user,
	    bmcpassword         => $ipmi_pw,
	    mgt                 => "ipmi",
	    installnic          => 'bootif',
	    primarynic          => $private_if,
	    netboot             => $netboot,
	    os                  => $tgt_os,
	    arch                => $tgt_arch,
	    profile             => $profile,
	    provmethod          => $provmethod,
	    xcatmaster          => $master_ip,
	    nfsserver           => $master_ip,
	    domainadminuser     => $username,
	    domainadminpassword => $password,
	  }
	  if $ipmi_ip != undef {
	    if $ipmi_mac == undef {
	      fail "\$ipmi_ip IP Address ${ipmi_ip} needs a mac address defined in \$ipmi_mac"
	    }
	    xcat_node {  "${hostname}-ipmi" :
	      ensure  => $ensure,
	      groups  => [ "all" ],
	      ip      => $ipmi_ip,
	      mac     => $ipmi_mac,
	    }  	    
	  }
  }
  
  vcl_computer { $hostname :
    ensure        => $ensure,
    hostname      => $hostname,
    state         => $vcl_state,
    public_ip     => $public_ip,
    private_ip    => $private_ip,
    public_mac    => $public_mac,
    private_mac   => $private_mac,
    ram           => $ram,
    procnumber    => $procnumber,
    procspeed     => $procspeed,
    network       => $network,
    type          => $type,
    drivetype     => $drivetype,      
    deleted       => $deleted,       
    notes         => $notes,           
    location      => $location,       
    dsa           => $dsa,            
    dsapub        => $dsapub,         
    rsa           => $rsa,            
    rsapub        => $rsapub,         
    hostpub       => $hostpub,           
    platform      => $platform,         
    vclschedule   => $vclschedule,         
    image         => $image,            
    imagerevision => $imagerevision,    
    provisioning  => $provisioning,     
    vmhost        => $vmhost,
    vmtype        => $vmtype,
    vmprofile     => $vmprofile,
    vmlimit       => $vmlimit,
  }
  
  if $ensure == present and $vmhost == 'localhost' {
    include vswitch
    include virt
    
    if !defined(Vcl_computer['localhost']) {
      if $::memory == undef {
	      $hostram = $::memorysize
	    }
	    else {
	      $hostram = $::memory
	    }
	    if $::processorcount == undef {
	      $hostprocnumber = count($::processors)
	    }
	    else {
	      $hostprocnumber = $::processorcount
	    }
	    
	    $proc = split($::processor0, '@')
	    $hostprocspeed = strip($proc[1])
	    
      vcl_computer { 'localhost':
        ensure        => present,
		    public_ip     => '127.0.0.1',
		    state         => 'vmhostinuse',
        vmprofile     => 'KVM - local storage',
		    ram           => $hostram,
		    procnumber    => $hostprocnumber,
		    procspeed     => $hostprocspeed,
		    network       => 40000,   
		    provisioning  => 'None', 
      }
    }
    
    Vcl_computer['localhost'] -> Vcl_computer[$hostname]
    
    vs_port { "${hostname}_pub" :
      tag => $pubvlan,
      bridge => $::vclmgmt::pubbridge,
    }
    
    vs_port { "${hostname}_priv" :
      tag => $privlan,
      bridge => $::vclmgmt::privbridge,
    }
    
    if $usexcat == true {
      $pxe = true
    }
    else {
      $pxe = undef
    }
    
    virt { $hostname :
      interfaces => [ "${hostname}_priv", "${hostname}_pub" ],
      virt_path => $virtpath,
      pxe => $pxe,
    }
    
    Vs_port["${hostname}_pub"]  -> Virt[$hostname]
    Vs_port["${hostname}_priv"] -> Virt[$hostname]
  }
}
