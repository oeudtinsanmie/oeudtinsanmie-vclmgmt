Key Concepts
------------
The VCLmgmt module uses Puppet to configure VCL resources according to a specified manifest.  This document will briefly discuss the resources managed by the module, Puppet's approach to managing resources in general, and how VCL's resources work specifically.  For first-time Puppet users, a quick start guide is provided for getting Puppet running on your Redhat or CentOS environment.  Finally, a process for describing test scenarios as manifests is discussed and a simple example scenario is provided. 
([tl;dr](#puppet-quickstart-centos))

### Network Structure
A VCL Management Node is connected to the computers it provisions through the [public network and one or two private networks](https://cwiki.apache.org/confluence/display/VCL/Network+Layout).  The primary private network is responsible for pxe booting and delivering images to managed computers.  Optionally, another private network may be used to connect to a DRAC or Management Module.  The VCLmgmt puppet module expands on this network structure, allowing one or more "pods," private subnet or subnet pairs.  Computers in separate pods cannot communicate with each other over their private network(s), but can each still communicate with the management node.  The VCLmgmt module assumes is that a management node will use a single port for all primary private network subnets, and a single port if any for all secondary private network subnets.  Isolation is accomplished using different [VLANs](http://en.wikipedia.org/wiki/Virtual_LAN) for each pod. 

### Managed Computers
A computer, in this context, is a physical or virtual machine that is provisioned by the management node.  VCL tracks several properties of the computers it manages, storing them within database entries.  If VCL is deployed alongside xCAT, additional and duplicate information about a computer is stored within xCAT's tables. 

### Images
An image is a capture of a computer's hard drive state or the installation media for an initial load of a computer.  VCL tracks properties of images within its database and within xCAT's files if xCAT is being used to provide bare-metal provisioning.  

### Kickstart Templates
xCAT uses [kickstart templates](http://sumavi.com/sections/kickstart-templates) to generate kickstart files[[1]](https://docs.oracle.com/cd/E24628_01/em.121/e27046/appdx_pxeboot.htm#EMLCM12199)[[2]](http://wiki.centos.org/HowTos/NetworkInstallServer)[[3]](https://access.redhat.com/documentation/en-US/Red_Hat_Network_Satellite/5.3/html/Deployment_Guide/s1-provisioning-profiles.html) when provisioning physical computers.  

### Management Node Configuration
The management node, itself, has several properties that describe it.  
* Its two or three interfaces', along with their MAC and IP addresses
* The database root password, and a username and password for VCL to use
* An administrative account and password for VCL to use on provisioned machines
* The release or revision of VCL code to run on the management node
* Several more details, each of which has sane defaults, but may be explored more fully [here](https://github.com/oeudtinsanmie/oeudtinsanmie-vclmgmt/blob/master/README.md)

Puppet Resource Management
--------------------------

### Overview
[Puppet](https://docs.puppetlabs.com/) provides a DSL for describing configurations in a declarative manner, as a series of resource hashes.  Puppet's software determines the current state of an environment, compares that to the declared desired state, then executes any changes necessary to move to the desired state.  Plugins like Hiera and PuppetDB allow the resource hashes for environments to be stored as structured text or within a database.

### VCLmgmt Module Resources
#### [vclmgmt](https://github.com/oeudtinsanmie/oeudtinsanmie-vclmgmt/blob/master/README.md#vclmgmt-)
The core class configures the Management Node's settings.  

#### [vclmgmt::pod](https://github.com/oeudtinsanmie/oeudtinsanmie-vclmgmt/blob/master/README.md#vclmgmtpod-)
The pod class sets up the private network(s) for each pod in the network structure.  If xCAT is enabled, it also makes the appropriate xCAT network table entries.

#### [vclmgmt::computer](https://github.com/oeudtinsanmie/oeudtinsanmie-vclmgmt/blob/master/README.md#vclmgmtcomputer-)
The computer class sets up the VCL database entries and, if xCAT is enabled, manages the xCAT node entries for each computer.

#### [vclmgmt::baseimage](https://github.com/oeudtinsanmie/oeudtinsanmie-vclmgmt/blob/master/README.md#vclmgmtbaseimage-)
The baseimage class optionally downloads an installation disk, or imports an existing disk image into xCAT and makes the appropriate VCL database entries.

#### [xcat::template](https://github.com/oeudtinsanmie/oeudtinsanmie-xcat/blob/master/README.md#xcattemplate-)
The template class creates the xCAT template files for using pxe to provision managed computers.  This class requires some familiarity with pxe kickstart files to use effectively, but some working examples will be posted by VCL to get you started.

### Puppet Quickstart (CentOS)
This is a short set of instructions to get Puppet up and working quickly and painlessly with the VCLmgmt module and its supporting modules.  

```
yum install -y which tar
curl -sSL https://get.rvm.io | bash -s stable --ruby
rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
yum install -y puppet-server ruby-devel git
gem install librarian-puppet puppet
puppet resource package hiera ensure=installed
```

* Copy [Puppetfile](https://github.com/oeudtinsanmie/vcl-docker/blob/master/Puppetfile) to /etc/puppet/Puppetfile
* Copy [manifests/vclnode.pp](https://github.com/oeudtinsanmie/vcl-docker/blob/master/manifests/vclnode.pp) to /etc/puppet/manifests/{YOUR_HOSTNAME}.pp

```
cd /etc/puppet
librarian-puppet install --clean
```

Test Configuration Descriptions
-------------------------------

### Process Overview


### Simple Test Case0

