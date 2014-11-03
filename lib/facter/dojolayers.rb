Facter.add(:dojolayers) do
  
  setcode do
    vclweb = Facter.value(:vclweb)
    if vclweb == nil then
      Puppet.debug "vclweb not yet set.  No dojolayers definition available in utils.php"
      {}
    else
      utils = "#{vclweb}/.ht-inc/utils.php"
      Puppet.debug "Looking up vcldojo configuration from #{utils}"
      begin
        File.open(utils, 'r') { | file |
          layerfile = file.read()
          layers = {}
          layerfile.split("START DOJO PARSING\n")[1].split("# END DOJO PARSING")[0].split("break;").collect { | layerblob |
            if (layerblob.include? '=') then
              jnk1, name, deps = layerblob.split('=')
              name = name.split(';')[0].lstrip.rstrip.delete('\';') 
  
              deps = deps.split(',').collect { | line |
                jnk1, dep, jnk2 = line.split('\'')
                dep
              }.delete_if { | x | x == '' }
  
              layers[name] =  {
                "dependencies" => deps,
              }
            end
          }
          layers.delete(nil)
          layers
        }
      rescue Exception => e
        Puppet.debug "Could not find file #{utils}.  VCL installation was not available when facts were gathered.  Rerun puppet apply after vcl repo has been loaded"
        {}
      end
    end
  end
end