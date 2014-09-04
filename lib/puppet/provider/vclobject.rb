class Puppet::Provider::Vclobject < Puppet::Provider
  
  @@maintbl = "image"
  @@revtbl = nil #"imagerevision"
  @@columns = {
    "image"     => { 
      "name"          => :name, 
      "prettyname"    => :prettyname, 
      "minram"        => :minram, 
      "minprocnumber" => :minprocnumber, 
      "minprocspeed"  => :minprocspeed, 
      "minnetwork"    => :minnetwork, 
      "maxconcurrent" => :maxconcurrent, 
      "reloadtime"    => :reloadtime, 
      "deleted"       => :deleted, 
      "test"          => :test, 
      "lastupdate"    => :lastupdate, 
      "forcheckout"   => :forcheckout, 
      "project"       => :project, 
      "size"          => :size, 
      "architecture"  => :architecture, 
      "description"   => :description, 
      "usage"         => :usage 
    },
    "OS"        => { "name" => :os },
    "platform"  => { "name" => :platform }
  }
  @@wheres = { 
    "image.osid" => "OS.id", 
    "image.platformid" => "platform.id" 
  }
  @@tinyintbools = [ :deleted, :test, :forcheckout ]
    
  @@db = nil
  @@cmd_base = nil

  commands  :mysql => '/usr/bin/mysql'
    
  def initialize(value={})
    super(value)
    @property_flush = {}
    
    if (@@db == nil) then
      vcldconf = File.new("/etc/vcl/vcld.conf", "r")
      while (@@db == nil and line = vcldconf.gets)
        if line.start_with?("database") 
          @@db = line.split('=').at(1).strip.delete("'")
        end
      end
      @@cmd_base = ["--defaults-extra-file=/root/.my.cnf ", "-D", @@db, "-NBe"]
    end

  end
            
  def self.instances
    
    list_obj.collect { |obj|
      begin
        new(make_hash(obj))
      rescue StandardError => e
        raise Puppet::DevError, "Constructor failed: #{e}"
      end
    }

  end
  
  def self.list_obj 
    qry = "SELECT "

    @@columns.keys.each { |tbl|
      @@columns[tbl].each { |col, param| 
        qry << "#{tbl}.#{col}, "
      } 
    }
    
    qry << "GROUP_CONCAT(resourcegroup.name SEPARATOR ',') FROM #{@@tbls.join(", ")}, resource, resourcegroup, resourcegroupmembers" 

    qry << " WHERE"
    @@wheres.each { |key, val| qry << " #{key}=#{val} AND" }
    
    qry << " resource.subid=#{@@maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid GROUP BY image.id"
    
    cmd_list = @@cmd_base + [ qry ]

    begin
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    output.split("\n")
  end
  
  def self.make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split("\t")

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    i = 0
    @@columns.keys.each { |tbl|
      @@columns[tbl].each { |col, param|
        if (hash_list[i].include? ",")
          inst_hash[param] = hash_list[i].strip.split(",")
        else
          inst_hash[param] = hash_list[i].strip
        end
        i = i+1 
      } 
    }
    if (hash_list[i].include? ",")
      inst_hash[:groups] = hash_list[i].strip.split(",")
    else
      inst_hash[:groups] = hash_list[i].strip
    end

    inst_hash.merge!(inst_hash) { |key, oldval, val| val == 'NULL' ? nil : val }
    @@tinyintbools.each { |key| 
      if (inst_hash[key] == '1') then
        inst_hash[key] = :true
      else
        inst_hash[key] = :false
      end
    }

    Puppet::Util::symbolizehash(inst_hash)
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
  
  def self.paramVal (param)
    if @@tinyintbools.include?(param)
      if resource[param] == :true
        return "'1'"
      else
        return "'0'"
      end
    elsif resource[param] == nil
      return "NULL"
    end
    "'#{resource[param]}'"
  end
  
  def flush
    if (@property_flush and @property_flush[:ensure] == :absent)
      # remove rows
      qry = "DELETE FROM #{@@maintbl} WHERE name = '#{resource[:name]}'; " 
      if @@revtbl
        qry << "DELETE FROM #{@@revtbl} WHERE #{@@maintbl}id NOT IN (SELECT id FROM #{@@maintbl}); "
      end
      qry << "DELETE FROM resource WHERE resourcetypeid = resourcetype.id AND resourcetype.name=#{@@resourcetype} AND resource.subid NOT IN (SELECT id FROM #{@@maintbl}); "
      qry << "DELETE FROM resourcegroupmembers WHERE resourceid NOT IN (SELECT id FROM resource)"

      cmd_list = @@cmd_base + [ qry ]
      begin
        mysql(cmd_list)
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
      end
    else if (@property_flush and @property_flush[:ensure] == :present)
      # add base image
      qry  = "SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '#{@@db}' AND TABLE_NAME = '#{@@maintbl}'"
      
      cmd_list = @@cmd_base + [ qry ]
      begin
        objid = mysql(cmd_list).strip
      rescue Puppet::ExecutionFailure => e
        raise Puppet::DevError, "mysql #{cmd_list.join(' ')} had an error -> #{e}"
      end

      qry  = "INSERT INTO #{@@maintbl} (id, "
      vals = ""
      @@columns[@@maintbl].each { |col, param| 
        qry  << "#{@@maintbl}.#{col}, "
        vals << "#{paramVal(param)}, "
      }
      @@wheres.each { |img, totabl| 
        qry  << "#{img}, "
        vals << "#{totabl}, " 
      }
      
      qry.chomp!(", ")
      vals.chomp!(", ")
      othertbls = @@columns.keys
      othertbls.delete(@@maintbl)
      if (othertbls.length > 0)
        qry << ") SELECT NULL, "
        qry << vals

        qry << " FROM #{othertbls.join(", ")}"
        qry << " WHERE"
        othertbls.each { |tbl|
          @@columns[tbl].each { |col, param|
            qry << " #{tbl}.#{col} = #{paramVal(param)} AND"
          }
        }
        qry.chomp!(" AND")
      else
        qry << ") VALUES (NULL, "
        qry << vals
        qry << ")"
      end

      qry << "; "
      qry << "INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename) "
      qry <<                    "VALUES (NULL, '#{imageid}', '1', '1', NOW(), '1', '#{resource[:name]}' ); "
      qry << "INSERT INTO resource (id, resourcetypeid, subid) VALUES (NULL, '13', '#{imageid}');"

      if resource[:deleted] then
        qry << " UPDATE imagerevision SET deleted = '1', datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = '#{resource[:name]}'); "
      end

      cmd_list = @@cmd_base + [ qry ]
      begin
        mysql(cmd_list)
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
      end
    else
      # change existing definition
      qry = "UPDATE #{@@tbls.join(", ")} SET"
      @@columns["image"].each { |col, param|
        if @@tinyintbools.include?(param) then
          if resource[param] == :true then
            qry << " image.#{col}='1',"
          else
            qry << " image.#{col}='0',"
   	      end  
        elsif resource[param] == nil then
          qry << " image.#{col}=NULL,"
   	    else
          qry << " image.#{col}='#{resource[param]}',"
        end  
      } 
      @@wheres.each { |img, totabl|
        qry << " #{img}=#{totabl},"
      }
      qry.chomp!(",")
      othertbls = @@columns.keys
      othertbls.delete("image")
      if (othertbls.length > 0)
        qry << " WHERE"
        othertbls.each { |tbl| 
          @@columns[tbl].each { |col, param|
            if @@tinyintbools.include?(param) then
              if resource[param] == :true then
                qry << " #{tbl}.#{col}='1' AND"
              else
                qry << " #{tbl}.#{col}='0' AND"
              end
            elsif resource[param] == nil then
              qry << " #{tbl}.#{col}=NULL AND"
            else
              qry << " #{tbl}.#{col}='#{resource[param]}' AND"
            end
          }
        }
        qry << " image.name = '#{resource[:name]}';"
      else
        qry << " WHERE image.name = '#{resource[:name]}';"
      end

   	  if @property_flush[:deleted] then
        qry << " UPDATE imagerevision SET deleted = '1', datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = '#{resource[:name]}'); "
   	  end

      cmd_list = @@cmd_base + [ qry ]
      begin
        mysql(cmd_list)
      rescue Puppet::ExecutionFailure => e
        raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
      end
    end
  end
end

