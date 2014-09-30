require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vcldojo'))
Puppet::Type.type(:vcldojo_prefix).provide(:default, :parent => Puppet::Provider::Vcldojo) do

  mk_resource_methods
  
  def self.make_hash (obj)
    { 
      :name => obj[0],
      :path => obj[1],
    }
  end

  def isme? (entry)
    entry[0] == resource[:name]
  end
  
  def dehash (hash)
    [ hash[:name], hash[:path], ]
  end
  
  def self.dojotype
    "prefixes"
  end
end

