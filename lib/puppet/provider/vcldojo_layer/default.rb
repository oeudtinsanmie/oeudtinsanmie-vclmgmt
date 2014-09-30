require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vcldojo'))
Puppet::Type.type(:vcldojo_layer).provide(:default, :parent => Puppet::Provider::Vcldojo) do

  mk_resource_methods
  
  def isme? (entry)
    entry[:name] == resource[:name]
  end
  
  def dehash (hash)
    {
      "name" => hash[:name],
      "dependencies" => hash[:dependencies],
    }
  end
  
  def self.dojotype
    "layers"
  end
end
