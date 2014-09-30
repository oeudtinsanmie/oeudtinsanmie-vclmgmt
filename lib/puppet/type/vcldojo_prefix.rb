# This has to be a separate type to enable collecting
Puppet::Type.newtype(:vcl_computer) do
  @doc = 'manages the mysql tables for a base image in vcl.'

  ensurable
  
  newparam(:name, :namevar=>true) do
    desc ''
  end
  
  newproperty(:path) do
    desc ''
  end

end
