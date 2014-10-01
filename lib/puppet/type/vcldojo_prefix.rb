# This has to be a separate type to enable collecting
Puppet::Type.newtype(:vcldojo_prefix) do
  @doc = 'dojo prefix definitions for dojo profile of vcl.'

  ensurable
  
  newparam(:name, :namevar=>true) do
    desc ''
  end
  
  newproperty(:path) do
    desc ''
  end

end
