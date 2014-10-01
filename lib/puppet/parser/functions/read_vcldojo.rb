require 'set'
module Puppet::Parser::Functions
  newfunction(:read_vcldojo, :type => :rvalue) do |args|
    utils = args[0]
    
    Puppet.debug "Looking up vcldojo configuration from #{utils}"
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
  end
end
