Puppet::Type.type(:vcl_image).provide(:mysql) do

  @@tbls = [ "image", "OS", "platform" ]
  @@maintbl = "image"
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

  mk_resource_methods
  
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
    
    list_obj().collect { |obj|
      begin
        new(make_hash(obj))
      rescue StandardError => e
        raise Puppet::Error, "Constructor failed: #{e}"
      end
    }

  end
  
  def self.list_obj (obj_name = nil)
    qry = "SELECT "

    @@tbls.each { |tbl|
      @@columns[tbl].each { |col, param| 
        qry << "#{tbl}.#{col}, "
      } 
    }
    qry.chomp!(", ")
    
    qry << " FROM #{@@tbls.join(", ")}" 

    if @@wheres.length > 0
      qry << " WHERE"
      @@wheres.each { |key, val| qry << " #{key}=#{val} AND" }
      
      if (obj_name != nil)
        qry << " image.name = '#{obj_name}'"
      else
        qry.chomp!(" AND")
      end
    elsif (obj_name != nil)
      qry << " WHERE image.name = '#{obj_name}'"
    end

    cmd_list = @@cmd_base + [ qry ]

    begin
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    output
  end
  
  def self.make_hash(obj_str)
    if (obj_str == nil) 
      return {}
    end
    
    hash_list = obj_str.split("\t")

    inst_hash = Hash.new

    inst_hash[:ensure] = :present
    i = 0
    @@tbls.each { |tbl|
      @@columns[tbl].each { |col, param|
        inst_hash[param] = hash_list[i].strip
        i = i+1 
      } 
    }

    inst_hash.merge!(inst_hash) { |key, oldval, val| val == 'NULL' ? nil : val }
    @@tinyintbools.each { |key| 
      if (inst_hash[key] == '1') then
        inst_hash[key] = :true
      else
        inst_hash[key] = :false
      end
    }

#    debug = "\n{\n"
#    inst_hash.each { |key, val| debug << "#{key} => #{val},\n" }
#    debug << "}\n\n"
#    Puppet.debug(debug)

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
    if !@property_flush.empty? then
      if (@property_flush[:ensure] == :absent)
        # remove rows
        qry = "DELETE FROM image WHERE name = '#{resource[:name]}'; " 
        qry <<  "DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image); "
        qry <<  "DELETE FROM resource WHERE resourcetypeid = '13' AND subid NOT IN (SELECT id FROM image); "

        cmd_list = @@cmd_base + [ qry ]
        begin
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
        @property_hash.clear
      else
        if (@property_flush[:ensure] == :present) then
          # add base image
          qry  = "SELECT AUTO_INCREMENT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '#{@@db}' AND TABLE_NAME = 'image'"
          
          cmd_list = @@cmd_base + [ qry ]
          begin
            imageid = mysql(cmd_list).strip
            Puppet.debug(imageid)
          rescue Puppet::ExecutionFailure => e
            raise Puppet::Error, "mysql #{cmd_list} had an error -> #{e}"
          end

          qry  = "INSERT INTO image (id, "
          vals = ""
          @@columns["image"].each { |col, param| 
            qry  << "image.#{col}, "
            if @@tinyintbools.include?(param) then
              if resource[param] == :true then
                vals << "'1', "
              else
                vals << "'0', "
              end
            elsif resource[param] == nil then
              vals << "NULL, "
            else
              vals << "'#{resource[param]}', "
            end  
          }
          @@wheres.each { |img, totabl| 
            qry  << "#{img}, "
            vals << "#{totabl}, " 
          }
          qry.chomp!(", ")
          vals.chomp!(", ")
          othertbls = @@columns.keys
          othertbls.delete("image")
          if (othertbls.length > 0)
            qry << ") SELECT NULL, "
            qry << vals

            qry << " FROM #{othertbls.join(", ")}"
            qry << " WHERE"
            othertbls.each { |tbl|
              @@columns[tbl].each { |col, param|
                if @@tinyintbools.include?(param) then
                  if resource[param] == :true then
                    qry << " #{tbl}.#{col} = '1' AND"
                  else
                    qry << " #{tbl}.#{col} = '0' AND"
                  end
                elsif resource[param] == nil then   
                  qry << " #{tbl}.#{col} = NULL AND"
                else
                  qry << " #{tbl}.#{col} = '#{resource[param]}' AND"
                end
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
      @property_flush.clear
      @flush_needed = :false
      # refresh @property_hash
      @property_hash = make_hash(list_obj(resource[:name]))
    end
  end
end

