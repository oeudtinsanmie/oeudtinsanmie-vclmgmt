Puppet::Type.type(:vcl_image).provide(:mysql) do

  @@columns = [ "name", "prettyname", "platformid", "osid", "minram", "minprocnumber", "minprocspeed", "minnetwork", "maxconcurrent", "reloadtime", "deleted", "test", "lastupdate", "forcheckout", "project", "size", "architecture", "description", "image.usage" ]
  @@db = nil
#  @@pw = nil
#  @@usr = nil
  @@cmd_base = nil

  mk_resource_methods
  
  commands  :mysql => '/usr/bin/mysql'
    
  def initialize(value={})
    super(value)
    @property_flush = {}
    
    # or @@pw == nil or @@usr == nil
    if (@@db == nil) then
      vcldconf = File.new("/etc/vcl/vcld.conf", "r")
      while (@@db == nil and line = vcldconf.gets)
        if line.start_with?("database") 
          @@db = line.split('=').at(1).strip.delete("'")
#        elsif line.start_with?("wrtPass") 
#          @@pw = line.split('=').at(1).strip.delete("'")
#        elsif	line.start_with?("LockerWrtUser") 
#          @@usr = line.split('=').at(1).strip.delete("'")
        end
      end
      # @@cmd_base = ["-D", @@db, "--user='#{@@usr}'", "--host=localhost", "--password='#{@@pw}'", "-Ne"]
      @@cmd_base = ["--defaults-extra-file=/root/.my.cnf ", "-D", @@db, "-NBe"]
    end

  end
            
  def self.instances
    
    list_obj().collect { |obj|
      new(make_hash(obj))
    }
  end
  
  def list_obj (obj_name = nil)
    qry = "select #{@@columns.join(', ')} from image"
    if (obj_name != nil)
      qry << "WHERE name = '#{obj_name}'"
    end
    cmd_list = @@cmd_base + [ qry ]
    # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]

    begin
      Puppet.debug(cmd_list.join(" "))
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    output
  end

  def self.list_obj (obj_name = nil)
    qry = "select #{@@columns.join(', ')} from image"
    if (obj_name != nil)
      qry << "WHERE name = '#{obj_name}'"                                
    end
    cmd_list = @@cmd_base + [ qry ]
    # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]

    begin
      Puppet.debug(cmd_list.join(" "))
      output = mysql(cmd_list)
      Puppet.debug(output)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e}"
      return {}
    end

    output
  end
  
  def self.make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    @@columns.each_index { |i|
      if (hash_list[i+1] != 'NULL') then
        inst_hash[@@columns[i].delete("image.")] = hash_list[i+1]
      end 
    }
    
    inst_hash
  end
  
  def make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    @@columns.each_index { |i|
      if (hash_list[i+1] != 'NULL') then  
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
      if (@property_flush[:ensure] == :absent)
        # remove rows
        qry = "DELETE FROM image WHERE name = #{resource[:name]}; " 
        qry <<  "DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image); "
        qry <<  "DELETE FROM resource WHERE resourcetypeid = '13' AND subid NOT IN (SELECT id FROM image); "

        cmd_list = @@cmd_base + [ qry ]
        # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]
        begin
          Puppet.debug(cmd_list.join(" "))
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
        @property_hash.clear
        @property_flush = nil
        return
      elsif (@property_flush[:ensure] == :deleted)
        # mark image as deleted
        qry = "UPDATE imagerevision SET deleted = '1', datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = #{resource[:name]}); "
        qry <<  "UPDATE image SET deleted = '1' WHERE name = #{resource[:name]}; "

        cmd_list = @@cmd_base + [ qry ]
        # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]
        begin
          Puppet.debug(cmd_list.join(" "))
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
      else
        if (@property_flush[:ensure] == :present) then
          # add base image
          qry  = "SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '#{@@db}' AND TABLE_NAME = 'image'"
          
          cmd_list = @@cmd_base + [ qry ]
          # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]
          begin
            Puppet.debug(cmd_list.join(" "))
            imageid = mysql(cmd_list).strip
            Puppet.debug(imageid)
          rescue Puppet::ExecutionFailure => e
            Puppet.debug "mysql #{cmd_list} had an error -> #{e}"
            return {}
          end

          Puppet.debug(imageid)

          qry = "INSERT INTO image (id, #{@@columns.join(", ")}) VALUES (NULL, "

          Puppet.debug(qry)
          
          @@columns.each { |col|
            if (resource[col] != nil) 
              qry << "'#{resource[col]}', "
            else
              qry << "NULL, " 
            end
          }

       	  Puppet.debug(qry)

          if qry.end_with?(", ")
            qry.chomp!(", ")
          end

       	  Puppet.debug(qry)

          qry << "); "
          qry << "INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename) "
          qry <<                    "VALUES (NULL, #{imageid}, '1', '1', NOW(), '1', #{resource[:name]} ); "
          qry << "INSERT INTO resource (id, resourcetypeid, subid) VALUES (NULL, '13', #{imageid});"

       	  Puppet.debug(qry)

          cmd_list = @@cmd_base + [ qry ]
          # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]
          begin
            Puppet.debug(cmd_list.join(" "))
            mysql(cmd_list)
          rescue Puppet::ExecutionFailure => e
            raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
          end
        else
          # change existing definition
          qry = "UPDATE image SET "
          @@columns.each { |col| qry << "#{col}=#{resource[col]}, " }
       	  if qry.end_with?(", ")
       	    qry.chomp!(", ")
       	  end
          qry << "WHERE name = #{resource[:name]}; "

          cmd_list = @@cmd_base + [ qry ]
          # cmd_list = @@cmd_base + [ "\"#{qry}\"" ]
          begin
            Puppet.debug(cmd_list.join(" "))
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

