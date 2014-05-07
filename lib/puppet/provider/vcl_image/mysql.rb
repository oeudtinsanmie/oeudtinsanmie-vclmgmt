Puppet::Type.type(:vcl_image).provide(:mysql) do

  @@columns = [ "name", "prettyname", "platformid", "osid", "minram", "minprocnumber", "minprocspeed", "minnetwork", "maxconcurrent", "reloadtime", "deleted", "test", "lastupdate", "forcheckout", "project", "size", "architecture", "description", "image.usage" ]

  mk_resource_methods
  
  commands  :mysql => '/usr/bin/mysql'
    
  def initialize(value={})
    super(value)
    @property_flush = {}
    
    if (@@db == nil) then
      vcldconf = File.new("/etc/vcl/vcld.conf", "r")
      while (@@db == nil and line = vcldconf.gets)
        if line.startswith?("database") then
          @@db = line.split('=').at(1).strip
	  return
        end
      end
    end

  end
            
  def self.instances
    
    list_obj().collect { |obj|
      new(make_hash(obj))
    }
  end
  
  def list_obj (obj_name = nil)
    cmd_list = ["-D", @@db, "-Ne", '"select', @@columns.join(", "), 'from image' ]
    if (obj_name != nil)
      cmd_list += ['WHERE name = #{obj_name}']
    end
    cmd_list += ['"']
    
    begin
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    obj_strs = output.lines.select { |s| s.count("|") >= 2 }
  end

  def self.list_obj (obj_name = nil)
    cmd_list = ["-D", @@db, "-Ne", '"select', @@columns.join(", "), 'from image' ]
    if (obj_name != nil)
      cmd_list += ['WHERE name = #{obj_name}']
    end
    cmd_list += ['"']
    begin
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    obj_strs = output.lines.select { |s| s.count("|") >= 2 }
  end
  
  def self.make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split("|")

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    @@columns.each_index { |i|
      if (hash_list[i+1] != 'NULL')  
        inst_hash[@@columns[i].delete("image.")] = hash_list[i+1]
      end 
    }
    
    inst_hash
  end
  
  def make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split("|")

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    @@columns.each_index { |i|
      if (hash_list[i+1] != 'NULL')  
        inst_hash[@@columns[i].delete("image.")] = hash_list[i+1]
      end 
    }
    
    inst_hash
  end

  def self.prefetch(resources)
    instances.each { |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    }
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
    if @property_flush
      cmd_list = ["-D", @@db, "-Ne" ]
      if (@property_flush[:ensure] == :absent)
        # remove rows
        cmd_list += ['"DELETE FROM image WHERE name = #{resource[:name]};', 
                      'DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image);', 
                      'DELETE FROM resource WHERE resourcetypeid = \'13\' AND subid NOT IN (SELECT id FROM image); "']
        begin
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
        @property_hash.clear
        @property_flush = nil
        return
      else if (@property_flush[:ensure] == :deleted)
        # mark image as deleted
        cmd_list += ['"UPDATE imagerevision SET deleted = 1, datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = #{resource[:name]});',
                      'UPDATE image SET deleted = 1 WHERE name = #{resource[:name]}; "' ]
        begin
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
      else
        if (@property_flush[:ensure] == :present)
          # add base image
          cmd_one = cmd_list + ['"SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = \'#{@@db}\' AND TABLE_NAME = \'image\'"']
            
          begin
            imageid = mysql(cmd_one).delete("|").trim
          rescue Puppet::ExecutionFailure => e
            Puppet.debug "mysql #{cmd_one} had an error -> #{e.inspect}"
            return {}
          end
          
          cmd_list += ['"INSERT INTO image (id,', @@columns.join(", "), ') VALUES (NULL,']
          
          @@columns.each { |col|
            if (resource[col] != nil) 
              cmd_list += ['\'#{resource[col]}\',']
            else
              cmd_list += [ 'NULL,' ] 
            end
          }
          cmd_list += [');',
                       'INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename)', 
                                          'VALUES (NULL, #{imageid}, \'1\', \'1\', NOW(), \'1\', #{resource[:name]} );',
                       'INSERT INTO resource (id, resourcetypeid, subid) VALUES (NULL, \'13\', #{imageid});"']
          begin
            mysql(cmd_list)
          rescue Puppet::ExecutionFailure => e
            raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
          end
        else
          # change existing definition
          cmd_list += [ '"UPDATE image SET' ]
          @@columns.each { |col| cmd_list += ['#{col}=#{resource[col]},'] }
          cmd_list[-1].delete!(',')
          cmd_list += [ 'WHERE name = #{resource[:name]}; "' ]
          begin
            mysql(cmd_list)
          rescue Puppet::ExecutionFailure => e
            raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
          end
        end
      end
      @property_flush = nil
    end
    # refresh @property_hash
    @property_hash = self.make_hash(list_obj(resource[:name])[0])
  end
end

