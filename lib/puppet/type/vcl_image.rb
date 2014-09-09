# This has to be a separate type to enable collecting
Puppet::Type.newtype(:vcl_image) do
  @doc = 'manages the mysql tables for a base image in vcl.'

  ensurable
  
  newparam(:name, :namevar=>true) do
    desc ''
  end
  
  newproperty(:prettyname) do
    desc ''
  end
  
  # This is a way of managing array properties stored as strings and whose order does not matter
  # And so users can specify a one-entry list or a string, with the same result
  newproperty(:groups, :array_matching => :all) do
    desc 'resource groups this image belogs to. Valid groups are allImages, newimages, newvmimages, allVMimages'
    def insync?(is)
      # The current value may be nil and we don't
      # want to call sort on it so make sure we have arrays 
      # (@ref https://ask.puppetlabs.com/question/2910/puppet-types-with-array-property/)
      if is.is_a?(Array) and @should.is_a?(Array)
        is.sort == @should.sort
      elsif @should.is_a?(Array) and @should.length == 1
        is == @should[0]
      else
        is == @should
      end
    end

    def should_to_s(newvalue)
      newvalue.inspect
    end

    def is_to_s(currentvalue)
      currentvalue.inspect
    end
    validate do |value|
      if (value == nil) then 
        return
      end
      validvals = [ "allImages", "newimages", "newvmimages", "allVMimages" ]

      if value.is_a?(Array)
        value.each { |val|
          if !validvals.include? val
            raise ArgumentError, "#{val} is not a valid group for images.  Please use allImages, newimages, newvmimages and/or allVMimages"
          end
        }
      else
        if !validvals.include? value
          raise ArgumentError, "#{value} is not a valid group for images.  Please use allImages, newimages, newvmimages and/or allVMimages"
        end
      end
    end
    defaultto "allImages"
  end
  
  newproperty(:platform) do 
    desc ''
    newvalues(:i386, :i386_lab, :ultrasparc)
    
    defaultto :i386
  end
  
  newproperty(:os) do
    desc '
    ---------------+-----------------------------------------+---------+-------------
    name           | prettyname                              | type    | installtype
    ---------------+-----------------------------------------+---------+-------------
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
    vmwareubuntu   | Ubuntu (VMware)                         | linux   | vmware'
    
    newvalues(:sun4x_58, :win2k, :rhel3, :winxp, :realmrhel3, :realmrhel4, :win2003, :rh3image, :rhel4, :rh4image, :fc5image, :rhfc5, :vmwarewinxp, :rhfc7, :fc7image, :rhel5, :esx35, :vmwareesxwinxp, :realmrhel5, :sun4x_510, :centos5, :rh5image, :rhfc9, :fc9image, :winvista, :centos5image, :ubuntuimage, :vmwarewin2008, :win2008, :vmwarewinvista, :win7, :vmwarewin7, :vmwarelinux, :vmwarewin2003, 'esxi4.1', :vmwareosx, :rhel6, :rh6image, :fedora16, :fedoraimage, :vmwareubuntu)
    defaultto :centos5
  end
  
  newproperty(:minram) do
    desc ''
    
    defaultto 0
  end
  
  newproperty(:minprocnumber) do
    desc ''
    
    defaultto 0
  end
  
  newproperty(:minprocspeed) do
    desc ''
    
    defaultto 0
  end
  
  newproperty(:minnetwork) do
    desc ''
    
    defaultto 0
  end
    
  newproperty(:deleted) do
    desc ''
    newvalues(:true, :false)
    
    defaultto :false
  end
  
  newproperty(:maxconcurrent) do
    desc ''
  end
  
  newproperty(:reloadtime) do
    desc ''
    defaultto 10
  end
  
  newproperty(:test) do
    desc ''
    newvalues(:true, :false)
    
    defaultto :false
  end
  
  newproperty(:forcheckout) do
    desc ''
    newvalues(:true, :false)
    
    defaultto :true
  end
  
  newproperty(:project) do
    desc ''
    newvalues(:vcl, :hpc, :vclhpc)
    
    defaultto :vcl
  end
  
  newproperty(:size) do
    desc ''
    
    defaultto 0
  end

  newproperty(:architecture) do
    desc ''
    newvalues(:x86, :x86_64)
    
    defaultto :x86_64
  end
  
  newproperty(:description) do
    desc ''
  end
  
  newproperty(:usage) do
    desc ''
  end
end
