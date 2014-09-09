# This has to be a separate type to enable collecting
Puppet::Type.newtype(:vcl_image) do
  @doc = 'manages the mysql tables for a base image in vcl.'

  ensurable
  
  newparam(:hostname, :namevar=>true) do
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
      validvals = [ "allComputers", "All VM Computers" ]

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
    defaultto "allComputers"
  end
  
  newproperty(:platform) do 
    desc ''
    newvalues(:i386, :i386_lab, :ultrasparc)
    
    defaultto :i386
  end
  
  newproperty(:ram) do
    desc ''
    
    defaultto 0
  end
  
  newproperty(:procnumber) do
    desc ''
    
    defaultto 1
  end
  
  newproperty(:procspeed) do
    desc ''
    
    defaultto 0
  end
  
  newproperty(:network) do
    desc ''
    
    defaultto 100
  end

  newproperty(:public_ip) do
    desc 'ip of this computer on the public network'
    
  end 
  
  newproperty(:private_ip) do
    desc 'ip of this computer on the private network'
    
  end
  
  newproperty(:public_mac) do
    desc 'mac of this computer on the public network'
    
  end 
  
  newproperty(:private_mac) do
    desc 'mac of this computer on the private network'
    
  end
  
  newproperty(:type) do
    desc ''
    
    newvalues(:blade, :lab, :virtualmachine)
    defaultto :blade
  end
  
  newproperty(:drivetype) do
    validate do |value|
      if (value.length > 4) then
        raise ArgumentError, "drivetype must be 4 or fewer chars"
      end
      true
    end
    
    defaultto "hda"
  end
  
  newproperty(:deleted) do
    desc ''
    newvalues(:true, :false)
    
    defaultto :false
  end
  
  newproperty(:notes) do
    desc ''
  end
  
  newproperty(:location) do
    desc ''
  end
  
  newproperty(:dsa) do
    desc ''
  end
  
  
  newproperty(:dsapub) do
    desc ''
  end
  
  newproperty(:rsa) do
    desc ''
  end
  
  newproperty(:rsapub) do
    desc ''
  end
  
  newproperty(:hostpub) do
    desc ''
  end
  
  newproperty(:state) do
    desc ''
  end
  
  newproperty(:platform) do
    desc ''
  end
  
  newproperty(:schedule) do
    desc ''
  end
  
  newproperty(:image) do
    desc ''
  end
  
  newproperty(:imagerevision) do
    desc ''
  end
  
  newproperty(:provisioning) do
    desc ''
  end
  
  newproperty(:vmhost) do
    desc ''
  end
  
  newproperty(:vmtype) do
    desc ''
  end

end
