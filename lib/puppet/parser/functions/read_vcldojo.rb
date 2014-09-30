require 'set'
module Puppet::Parser::Functions
  newfunction(:read_vcldojo, :type => :rvalue) do |args|
    utils = args[0]
    
    File.open(utils, 'r') { | file |
      layers = file.read().split("START DOJO PARSING\n")[1].split("# END DOJO PARSING")[0].split("break;").collect { | layerblob |
        jnk1, name, jnk2, deps = layerblob.split('=')
        # { name => { "dependencies" => [ array of dependencies ] } }
        {
          name.lstrip.rstrip.delete('\';') => {
            "dependencies" => deps[5..-1].split('\n').collect { | line |
              line.lstrip.rstrip.delete('\'();')
            }.delete_if { | x | x == '' },
          },
        }
      }
    }
    layers
  end
end
