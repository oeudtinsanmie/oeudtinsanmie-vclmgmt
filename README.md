VCL Managment Module
====================
This module installs and configures xCAT and VCL, and profides puppet classes to manipulate the related xCAT and database tables VCL uses.  The current version supports VCL up to release-2.3.2-RC2.  Development is in process to support the new database schema in the upcoming release of 2.4.  xCAT installation and resource management use the related [xCAT module](https://github.com/oeudtinsanmie/oeudtinsanmie-xcat).

Classes
--------
  * [Vclmgmt](#vclmgmt-)
  * [Vclmgmt::pod](#vclmgmtpod-)
  * [Vclmgmt::vlan](#vclmgmtvlan-)
  * [Vclmgmt::computer](#vclmgmtcomputer-)
  * [Vclmgmt::Baseimage](#vclmgmtbaseimage-)
    
Hiera Usage & Custom Functions
------------------------------
  * [Hiera Yaml Example](#example-yaml-)
  * [Using the set_defaults Function](#set_defaults-usage-)
  
A Note on Puppet Resource Chaining
----------------------------------
Resource chains are declared in init.pp to make sure everything is processed in the correct order, and to protect your own resource declarations that depend on the vclmgmt class.  However, adding support for importing Dojo layers from the VCL utils.php file, as is currently common practice, breaks the Puppet Resource declaration / resolution model and cannot be sufficiently protected by resource chain declarations.  Since the layers cannot be declared until after the VCL svn repo is resolved, a second application of the Puppet manifest is required to fully install Dojo, as it is currently supported.  There are probably ways to plan around this limitation in future versions of the Vclmgmt Module and VCL code. 

Class Definitions
=================
vclmgmt 
--------
Installs xCAT and VCL from source, then configures the management node.  You can also include an array of hashes describing the vclmgmt::xcat_pod configurations for client subnets.  Pod configurations will inherit the private and impi mac addreses and interface names, by default.  Explicit definitions within the pods hash will override those defaults.  Chaining rules for vclmgmt classes with relation to the installation and xcat are also defined.

    class { "vclmgmt" :
        # public network parameters
        public_mac     => 'XX:XX:XX:XX:XX:XX',   # MAC address for public network interface                 (REQUIRED)
        public_if      => 'em1',                 # Interface name of public-network facing interface.       (default value)
        public_ip      => 'dhcp',                # IP address for public-network facing interface           (default value)
                                                                                                            
        # private network parameters (network for provisioning target computers)                            
        private_mac    => 'XX:XX:XX:XX:XX:XX',   # MAC address for private-network facing interface         (REQUIRED)   
        private_if     => 'em2',                 # Interface name of private-network facing interface       (default value)
        private_ip     => '172.20.0.1',          # IP address for private-network facing interface          (REQUIRED)
        private_domain => 'mydomain',            # Domain for private-network facing interface              (REQUIRED)
        
        # ipmi network parameters (connected to DRACs of target computers)
        ipmi_mac       => 'XX:XX:XX:XX:XX:XX',   # MAC address for ipmi-network facing interface            (REQUIRED)
        ipmi_if        => 'p4p1',                # Interface name of ipmi-network facing interface          (default value)
        ipmi_ip        => '172.25.0.1',          # IP address for ipmi-network facing interface             (REQUIRED)
        
        # database setup
        vcldb          => 'vcl',                 # Database used by vcl                                     (default value)
        vcluser        => 'vcluser@localhost',   # Database user for vcl                                    (default value)
        root_pw        => 'ANOTHER_PASSWORD',    # Database root password                                   (REQUIRED)
        vcluser_pw     => 'PASSWORD',            # Database vcl user password                               (REQUIRED)

        system_user    => 'root',                # Admin account used in provisioned computers              (default value)
        system_pw,                               # Password for root accout in provisioned computers        (REQUIRED)
        vclhost        => 'localhost',           # Address of vcl webface                                   (default value)
        serverip       => 'localhost',           # Address of vcl database                                  (default value)
        
        # Required for block reservation processing
        xmlrpc_user    => 'admin',               # must be the unityid field for a user in the user table   (default value)
        xmlrpc_pw,                               # Password for xmlrpc_user.                                (default value)  
                                                 # This parameter does not set the password.  It only fills out the vcld configuration file, so you can leave this default until you want to use block reservation processing and have set up a user for this purpose.
        xml_url,                                 # URL used to call block reservations                      (default value)
                                                 #
                                                 # From VCL documentation: the URL will be the URL of your VCL website with a few things on the end
                                                 # for example, if you install the VCL web code at https://vcl.example.org/vcl/
                                                 # set xmlrpc_url to https://vcl.example.org/vcl/index.php?mode=xmlrpccall
                                                 # Defaults to "https://$fqdn/vcl/index.php?mode=xmlrpccall" 
        
        poddefaults    => {},                    # Default values applied to pod hashes supplied in the class definition.  Pod values take precedence over poddefaults, which take precedence over defaults derived from the management node definition
        pods           => undef,                 # Hashes defining public/private/ipmi tuples (pods) supported by this management node.  If not undef, these hashes will be populated with default values from the management node and declared as puppet resources
            
        vcldir         => '/vcl',                # Directory in which to place vcl svn repo                 (default value)
        dojo           => '1.6.1',               # Dojo version                                             (default value)
        dojotheme      => "tundra",              # dijit theme to apply to VCL webpages                     (default value)
        vclweb         => '/var/www/html/vcl',   # VCL web folder location                                  (default value)
        vclnode        => '/usr/local/vcl',      # Alias within standard path for vcl directory             (default value)
        
        firewalldefaults  => {                   # Set pre and post class requirements for the firewall declarations  (default value)
            require  => Class['ncsufirewall::pre'],
            before   => Class['ncsufirewall::post'],
        },
        
        vclversion     => "release-2.3.2-RC2",   # The release of vcl to pull from the repo, or "latest" if you want to work with the trunk  (default value)
        vclrevision    => undef,                 # If defined, pulls a specific revision of the vcl subversion repo                          (default value)
        usexcat        => false,                 # Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers  (default value)
    }

vclmgmt::pod 
------------------
Describes the private and ipmi subnets for a given collection of compute nodes.  It accepts hashes defining the vlan objects for its private and ipmi subnets, as well as a defaults hash, which may be used to contain any values shared by both definitions.  In addition, you may include a hash describing the computer objects of this pod.  Compute nodes within this list will be passed definitions from the pod within their defaults hash, describing the private and ipmi interfaces, networks and domains.  These will be overridden by any explicit definition in the computer hashes.

    vclmgmt::pod { "pod7a" : 
        private_hash => {                         # A vlan hash for the private network
            vlan_alias_ip => '192.168.37.1',
            network       => '192.168.37.0',
            netmask       => '255.255.255.192',
            domain        => 'mydomain',
            vlanid        => '307',
        },
        ipmi_hash => {                            # A vlan hash for the ipmi network
            network       => '192.168.137.0',
            netmask       => '255.255.255.192',
            domain        => 'ipmidomain',
            vlanid        => '1307',
        },
        defaults => {                             # Default values for node definitions within the nodes hash, if defined
            tgt_if        => 'eth1',      
            ipmi_user     => 'SOMEUSR',   
            ipmi_pw       => 'SOMEPASS',  
            admin_user    => 'adminuser', 
            admin_pw      => 'adminpass', 
        },
        nodes => {                                # Hash of vclmgmt::computers to declare with this network pair's settings
            "my-node" => {
                tgt_ip    => "192.168.37.8",
                ipmi_ip   => "192.168.137.8",
                tgt_mac   => "XX:XX:XX:XX:XX:XX",
                ipmi_mac  => "XX:XX:XX:XX:XX:XX",
            },
        },
        usexcat           => false,               # Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers  (default value)
      }

vclmgmt::vlan 
-------------------
Creates an xcat network object in xcat describing the network.  If vlan_alias_ip is not undefined, it will also create a network interface for the vlan.

    vclmgmt::vlan { "some_network" :
        master_if     => 'eth0', 
        master_mac    => 'XX:XX:XX:XX:XX:XX',   # MAC address for network interface
        master_ip     => '192.168.37.1',        # IP address for xcat management node on master_if
        vlan_alias_ip => undef,                 # IP address for xcat management node on the subnet routed through this vlan, or undef if no vlan is used                 
        domain        => 'mydomain',            # the domain name for this network
        network       => '192.168.37.0'         # network root address  
        netmask       => '255.255.255.192',     # netmask for network
        vlanid        => undef,                 # vlan id, if defining a subnet isolated by a vlan on this interface.  Ignored if no vlan_alias_ip provided
        usexcat       => false,                 # Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers  (default value)
    }

vclmgmt::computer 
----------------------
Defines related vcl_computer and xcat_node objects for a provision controlled computer.  Vcl_computer is a defined type within the vclmgmt module and manages [VCL Database Tables](https://vcl.apache.org/dev/database-schema.html#computer-table) related to computers, whereas xcat_node is a defined type within the related [xCAT module](https://github.com/oeudtinsanmie/oeudtinsanmie-xcat#xcat-objects-).  Where the computer table uses foreign keys to store properties of the computer, Vcl_computer abstracts this out.  For example, if I made an image called 'centos65' that I wish to load on this computer, I would simply put its name in the image field.

    vclmgmt::computer { "my-node" :
        ensure        => present,                       # Passthrough for ensurable objects in this class
        hostname      => $title,                        # Allows names of objects to be different from title of this resource
        public_ip,                                      # IP address for this computer on the public network
        public_mac,                                     # MAC address of this computer's interface on the public network 
        private_ip    => '192.168.37.8',                # IP address for target node on private network 
        private_mac   => 'XX:XX:XX:XX:XX:XX',           # MAC address for private network interface 
        private_if    => 'eth1',                        # interface of target node connected to its private network arget node
        ipmi_ip       => '192.168.137.8',               # IP address for target node on ipmi network 
        ipmi_mac      => 'XX:XX:XX:XX:XX:XX',           # MAC address for ipmi network interface 
        ipmi_user     => 'SOMEUSR',                     # username for ipmi on target node 
        ipmi_pw       => 'SOMEPASS',                    # password for ipmi on target node 
        master_ip,                                      # IP Address of management node (For the private network interface, not its vlan alias)
        xcat_groups   => [ 'ipmi', 'compute', 'all' ],  # Groups to add this computer to within xCAT
        vcl_groups    => [ 'allComputers' ],            # Groups to add this computer to within VCL. Valid groups are 'allComputers', 'All VM Computers'
        tgt_os        => 'centos',                      # OS to provision this computer with 
        tgt_arch      => 'x86_64',                      # Architecture of target node. 
        profile,                                        # Profile to apply when provisioning this computer
        username      => 'adminuser',                   # username to create as administrator on target node 
        password      => 'adminpass',                   # password for administrator account on target node
        netboot       => 'pxe',                         # Netboot method for provisioning
        provmethod    => 'install',                     # Provisioning method
        
        # vcl_computer parameters default to undef -> inherits defaults from vcl_computer
        ram           => undef,                         # Amount of RAM in this computer 
        procnumber    => undef,                         # Number of processors on this computer
        procspeed     => undef,                         # Processor speed of this computer
        network       => undef,                         # Network speed of this computer
        type          => undef,                         # Type of this computer. Valid values are blade, lab, or virtualmachine
        drivetype     => undef,                         # Type of hard drives within this computer. drivetype must be 4 or fewer chars. Default is hda
        deleted       => undef,                         # Whether this computer record should be marked deleted within the database
        notes         => undef,                         # Notes for this computer
        location      => undef,                         # Physical location of this computer
        
        # Not currently being used by VCL, according to documentation.  Was supposed to be for ssh
        dsa           => undef,                         
        dsapub        => undef,                         
        rsa           => undef,                          
        rsapub        => undef,                          
        hostpub       => undef,                          
        
        platform      => undef,                         # VCL platform designation of this computer. Valid values are i386, i386_lab, or ultrasparc
        vclschedule   => undef,                         # Schedule to assign this computer within VCL
        image         => undef,                         # Name of image to assign this computer
        imagerevision => undef,                         # Image revision number to assign this computer
        provisioning  => undef,                         # Provisioning method for this computer
        vmhost        => undef,                         # VM Host of this computer
        vmtype        => undef,                         # VM Type of this computer
        usexcat       => false,                         # Whether to install xCAT and configure parallel xCAT objects along with VCL database definitions for images and computers  (default value)
    }
      
vclmgmt::baseimage 
-------------------
Creates the database rows for a vcl base image, and creates an image within xcat, using the [xcat::image](https://github.com/oeudtinsanmie/oeudtinsanmie-xcat#xcatimage-) class.  Some of these parameters are enumerations from the Apache VCL project.  With the exception of the os code, everything else should work using only the default values.  If your configuration needs non-default values, refer to [VCL documentation](https://vcl.apache.org/dev/database-schema.html#image-table) for more details.

    vclmgmt::baseimage { "base-img" :
        ensure        => present,                   # Passthrough for ensurable objects in this class
        prettyname    => "Base Image Name",         # Long display name for this image in VCL
        platform      => 'i386',                    # VCL platform attribution for this image (may be i386, i386_lab, or ultrasparc)
        os            => 'centos5',                 # OS of this image 
        minram        => 512,                       # Min RAM requirement for this image
        minprocnumber => 1,                         # Min number of processors requirement for this image
        minprocspeed  => 1024,                      # Min processor speed requirement for this image
        minnetwork    => 100,                       # Min network speed requirement for this image
        maxconcurrent => undef,                     # maximum concurrent reservations that can be made for image
        test          => false,                     # flag to show if there is a test version of this image available (depricated?)        
        forcheckout   => true,                      # Assign this image for checkout
        project       => 'vcl',                     # Project within which this image is available. Valid values are vcl, hpc, or vclhpc
        size          => 1500,                      # Size of this image
        architecture  => 'x86_64',                  # Architecture this image targets. Valid values are x86 or x86_64
        description   => undef,                     # Description for this image 
        usage         => undef,                     # notes on how to use image displayed on Connect page
        deleted       => false,                     # Whether this image should be marked deleted
        
        # Parameters for the xcat::image class.  The architecture parameter, above, is used for xcat::image -> arch.
        url           => undef,                     # URL from which to download the iso for this image
        filepath      => '/images/baseimg.iso',     # File location of the iso for this image
        distro        => "centos6.5",               # OS distribution identifier of this image
    }

Here are the os codes currently available:

    name           | prettyname                              | type    | installtype
    ---------------|-----------------------------------------|---------|-------------
    sun4x_58       | Solaris 5.8 (Lab)                       | unix    | none       
    win2k          | Windows 2000 (Bare Metal)               | windows | partimage  
    rhel3          | Red Hat Enterprise Linux 3 (Kickstart)  | linux   | kickstart  
    winxp          | Windows XP (Bare Metal)                 | windows | partimage  
    realmrhel3     | Red Hat Enterprise Linux 3 (Lab)        | linux   | none       
    realmrhel4     | Red Hat Enterprise Linux 4 (Lab)        | linux   | none       
    win2003        | Windows 2003 Server (Bare Metal)        | windows | partimage  
    rh3image       | Red Hat Enterprise Linux 3 (Bare Metal) | linux   | partimage  
    rhel4          | Red Hat Enterprise Linux 4 (Kickstart)  | linux   | kickstart  
    rh4image       | Red Hat Enterprise Linux 4 (Bare Metal) | linux   | partimage  
    fc5image       | Fedora Core 5 (Bare Metal)              | linux   | partimage  
    rhfc5          | Fedora Core 5 (Kickstart)               | linux   | kickstart  
    vmwarewinxp    | Windows XP (VMware)                     | windows | vmware     
    rhfc7          | Fedora Core 7 (Kickstart)               | linux   | kickstart  
    fc7image       | Fedora Core 7 (Bare Metal)              | linux   | partimage  
    rhel5          | Red Hat Enterprise Linux 5 (Kickstart)  | linux   | kickstart  
    esx35          | VMware ESX 3.5 (Kickstart)              | linux   | kickstart  
    vmwareesxwinxp | Windows XP (VMware ESX)                 | windows | vmware     
    realmrhel5     | Red Hat Enterprise Linux 5 (Lab)        | linux   | none       
    sun4x_510      | Solaris 10 (Lab)                        | unix    | none       
    centos5        | CentOS 5 (Kickstart)                    | linux   | kickstart  
    rh5image       | Red Hat Enterprise Linux 5 (Bare Metal) | linux   | partimage  
    rhfc9          | RedHat Fedora Core 9 (Kickstart)        | linux   | kickstart  
    fc9image       | Red Hat Fedora Core 9 (Bare Metal)      | linux   | partimage  
    winvista       | Windows Vista (Bare Metal)              | windows | partimage  
    centos5image   | CentOS 5 (Bare Metal)                   | linux   | partimage  
    ubuntuimage    | Ubuntu (Bare Metal)                     | linux   | partimage  
    vmwarewin2008  | Windows Server 2008 (VMware)            | windows | vmware     
    win2008        | Windows Server 2008 (Bare Metal)        | windows | partimage  
    vmwarewinvista | Windows Vista (VMware)                  | windows | vmware     
    win7           | Windows 7 (Bare Metal)                  | windows | partimage  
    vmwarewin7     | Windows 7 (VMware)                      | windows | vmware     
    vmwarelinux    | Generic Linux (VMware)                  | linux   | vmware     
    vmwarewin2003  | Windows 2003 Server (VMware)            | windows | vmware     
    esxi4.1        | VMware ESXi 4.1                         | linux   | kickstart  
    vmwareosx      | OSX Snow Leopard (VMware)               | osx     | vmware     
    rhel6          | Red Hat Enterprise 6 (Kickstart)        | linux   | kickstart  
    rh6image       | Red Hat Enterprise 6 (Bare Metal)       | linux   | partimage  
    fedora16       | Fedora 16 (Kickstart)                   | linux   | kickstart  
    fedoraimage    | Fedora 16 (Bare Metal)                  | linux   | partimage  
    vmwareubuntu   | Ubuntu (VMware)                         | linux   | vmware

Hiera Usage
===========
vclmgmt::pod and vclmgmt::computer are set up as a hierarcy.  This makes it easy to define values in hiera once and let those definitions cascade through.  Variables are passed down the hierarchy as default values for lower member classes, but may be overridden by explicit definitions.  The simplest way to do this is to define all your networks and nodes in a hash within the vclmgmt class definition.  You can use Puppet's automatic variable importing or define a hash and then declare a class resource with that hash.  Alternatively, you might want to define a hash-generating function that defines network addresses according to some scheme (eg. by lab room, rack number, etc).  In that case, you may use the set_defaults function discussed below to recreate the hierarchy inheritance of the main class for your generated hashes.

Example Yaml 
-------------
The nested hash structure and default-passing behavior of these puppet classes simplify defining a VCL installation in hiera, and then using the hiera_include, ensure_resource and create_resources functions. 

    ---
    mgmt_node:
        usexcat: true
        vcluser_pw: vcl_sql_password
        root_pw: root_sql_password
        ipmi_mac: XX:XX:XX:XX:XX:XX
        private_mac: XX:XX:XX:XX:XX:XX
        public_mac: XX:XX:XX:XX:XX:XX
        private_if: em2
        private_ip: 192.168.0.5
        private_domain: mydomain
        ipmi_if: p4p1
        ipmi_ip: 192.168.100.5
        pods:
            my-pod:
                private_hash:
                    vlan_alias_ip: 192.168.37.1
                    network: 192.168.37.0
                    netmask: 255.255.255.192
                    domain: mypod.mydomain
                    vlanid: XXX
                ipmi_hash:
                    network: 192.168.137.0
                    netmask: 255.255.255.192
                    domain: ipmi.mypod.mydomain
                    vlanid: YYY
                defaults:
                    tgt_if: eth1
                    ipmi_user: SOMEUSER
                    ipmi_pw: SOMEPASS
                    admin_user: AdminUser
                    admin_pw: AdminPassword
                nodes:
                    my-node1:
                        public_ip: xxx.xxx.xxx.xxx
                        private_ip: 192.168.37.8
                        ipmi_ip: 192.168.137.8
                        public_mac: XX:XX:XX:XX:XX:XX
                        private_mac: XX:XX:XX:XX:XX:XX
                        ipmi_mac: XX:XX:XX:XX:XX:XX
                        notes: "My notes about this computer"
                    my-node2:
                        public_ip: xxx.xxx.xxx.xxx
                        private_ip: 192.168.37.72
                        ipmi_ip: 192.168.137.72
                        public_mac: XX:XX:XX:XX:XX:XX
                        private_mac: XX:XX:XX:XX:XX:XX
                        ipmi_mac: XX:XX:XX:XX:XX:XX

set_defaults Usage 
-------------------
The set_defaults function allows you to use the hierarchical default_passing behavior of the vclmgmt main class within your generated hash definitions.  It takes three arguments: a pod definitons hash, a defaults hash and a management node hash.  So, for example you could define your own pod definitions hash function of properties that describe your lab environment, and then use set_defaults to populate this generated hash with default values as if it were included within the vclmgmt class definition.

    ---
    classes:
        - class where I defined my_generation_function
    
    mgmt_node:
        vcluser_pw: vcl_sql_password
        root_pw: root_sql_password
        ipmi_mac: XX:XX:XX:XX:XX:XX
        private_mac: XX:XX:XX:XX:XX:XX
        public_mac: XX:XX:XX:XX:XX:XX
        private_if: em2
        private_ip: 192.168.0.5
        private_domain: mydomain
        ipmi_if: p4p1
        ipmi_ip: 192.168.100.5
        usexcat: true
    
    my_nodes:
        lab1:
            pod1a:
                rack: 1
                sub: a
            nodes:
                node1a1:
                    shelf: 1
                    type: onetypewehave
                node1a2:
                    shelf: 2
                    type: anothertypewehave
                node1a3:
                    shelf: 3
                    type: onetypewehave
            pod2c:
                rack: 1
                sub: c
            nodes:
                node2c1:
                    shelf: 1
                    type: someothertype
                node2c2:
                    shelf: 2
                    type: onetypewehave
                    
    my_defaults:
        private_if: em2
        tgt_os: centos6.5
        profile: centos65-test
        ipmi_user: root
        ipmi_pw: MY_PASSWORD

And then in puppet:

    hiera_include('classes')
    
    $mgmt_node = hiera_hash('mgmt_node')
    ensure_resource('class', 'vclmgmt', $mgmt_node)
    
    $mypods = hiera_hash('my_nodes', {})
    $mydefaults = hiera_hash('my_defaults', {})
    create_resources(vclmgmt::pod, set_defaults(my_generation_function($mypods), $mydefaults, $mgmt_node) )
    
    
