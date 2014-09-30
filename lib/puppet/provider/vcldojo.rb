require 'json'
require 'pp'
class Puppet::Provider::Vcldojo < Puppet::Provider
  
  File.open('/.vclweb', 'r') { | file | 
    @@vclprofile = "#{file.gets.delete('\n')}/dojo/util/buildscripts/profiles/vcl.profile.js"
  }
  
  File.open(@@vclprofile, 'r') { | file |
    @@dojo_hash = JSON.parse(file.read().split('=')[1])
  }
  
  def initialize(value={})
    super(value)
    @property_flush = {}
  end
  
  def self.prefetch (resources) 
    instances.each { |prov|
      if (resource = resources[prov.name]) then
        resource.provider = prov
      end
    }
  end
  
  def self.dojotype
    raise Puppet::DevError, "No dojotype defined for vcldojo child provider #{self.name}"
  end
  
  def self.instances
    @@dojo_hash[dojotype].collect { |obj|
      begin
        new(make_hash(obj))
      rescue StandardError => e
        raise Puppet::DevError, "Constructor failed: #{e}"
      end
    }
  end
  
  def self.make_hash (obj)
    Puppet::Util::symbolizehash(obj)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @property_flush[:ensure] = :present
  end
  
  def destroy
    @property_flush[:ensure] = :absent
  end
  
  def flush
    if (@property_flush[:ensure] != :present) then
      @@dojo_hash[self.class.dojotype].delete!(@@dojo_hash['dependencies'][self.class.dojotype].select { | entry |
        isme? entry
      })
    end
    
    if (@property_flush[:ensure] != :absent) then
      @@dojo_hash[self.class.dojotype] += [ dehash(resource.to_hash) ]
    end
    
    File.open(@@vclprofile, 'w') { | file |
      file.puts "dependencies = #{JSON.pretty_generate(@@dojo_hash)}"
    }
  end
  
end
