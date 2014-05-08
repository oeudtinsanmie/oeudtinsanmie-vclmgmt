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
  @@ensurestates = [ :deleted ]
    
  @@db = nil
  @@cmd_base = nil

  # copied from mk_resource_methods

  [resource_type.validproperties, resource_type.parameters].flatten.each do |attr|
    attr = attr.intern
    next if attr == :name
    define_method(attr) do
      if @property_hash[attr].nil?
        :absent
      else
        @property_hash[attr]
      end
    end

    define_method(attr.to_s + "=") do |val|
      if (@property_hash[attr] != val) then
        @property_hash[attr] = val
        @flush_needed = :true
      end
    end
  end

  
  commands  :mysql => '/usr/bin/mysql'
    
  def initialize(value={})
    super(value)
    @property_flush = {}
    @flush_needed = false
    
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
    
    spiffy = list_obj().collect { |obj|
      begin
        new(make_hash(obj))
      rescue StandardError => e
        raise Puppet::Error, "Constructor failed: #{e}"
      end
    }

    Puppet.debug("Spiffy::  " + spiffy.inspect)
    spiffy
  end
  
  def self.list_obj (obj_name = nil)
    qry = "SELECT "

    Puppet.debug(qry)

    @@tbls.each { |tbl|
      @@columns[tbl].each { |col, param| 
        qry << "#{tbl}.#{col}, "
      } 
    }
    qry.chomp!(", ")
    Puppet.debug(qry)
    
    qry << " FROM #{@@tbls.join(", ")}" 

    Puppet.debug(qry)

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

    Puppet.debug(qry)

    cmd_list = @@cmd_base + [ qry ]

    begin
      Puppet.debug(cmd_list.join(" "))
      output = mysql(cmd_list)
    rescue Puppet::ExecutionFailure => e
      Puppet.debug "mysql had an error -> #{e.inspect}"
      return {}
    end

    Puppet.debug(output)

    output
  end

  def list_obj (obj_name = nil)
    Puppet.debug("My list_obj")
    self.class.list_obj(obj_name)
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
      inst_hash[key] = (inst_hash[key] == '1')
    }
    @@ensurestates.each { |chk| 
      if inst_hash.delete(chk) then
        inst_hash[:ensure] = chk
      end
    }

    debug = "\n{\n"
    inst_hash.each { |key, val| debug << "#{key} => #{val},\n" }
    debug << "}\n\n"
    Puppet.debug(debug)

    inst_hash
  end

  def make_hash(obj_str)
    Puppet.debug("My make_hash")
    self.class.make_hash(obj_str)
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
    if !@property_flush.empty? or @flush_needed then
      if (@property_flush[:ensure] == :absent)
        # remove rows
        qry = "DELETE FROM image WHERE name = '#{resource[:name]}'; " 
        qry <<  "DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image); "
        qry <<  "DELETE FROM resource WHERE resourcetypeid = '13' AND subid NOT IN (SELECT id FROM image); "

        cmd_list = @@cmd_base + [ qry ]
        begin
          Puppet.debug(cmd_list.join(" "))
          mysql(cmd_list)
        rescue Puppet::ExecutionFailure => e
          raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
        end
        @property_hash.clear
      elsif (@property_flush[:ensure] == "deleted")
        # mark image as deleted
        qry = "UPDATE imagerevision SET deleted = '1', datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = #{resource[:name]}); "
        qry <<  "UPDATE image SET deleted = '1' WHERE name = #{resource[:name]}; "

        cmd_list = @@cmd_base + [ qry ]
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
          begin
            Puppet.debug(cmd_list.join(" "))
            imageid = mysql(cmd_list).strip
            Puppet.debug(imageid)
          rescue Puppet::ExecutionFailure => e
            Puppet.debug "mysql #{cmd_list} had an error -> #{e}"
            return {}
          end

          Puppet.debug(imageid)

          qry  = "INSERT INTO image (id, "
          vals = ""
          @@columns["image"].each { |col, param| 
            qry  << "image.#{col}, "
            if @@ensurestates.include?(param) then
              if resource[:ensure] == param then
                vals << "'1', "
              else
                vals << "'0', "
              end
            elsif @@tinyintbools.include?(param) then
              if resource[param] == param then
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
          Puppet.debug(qry)
          Puppet.debug(vals)
          @@wheres.each { |img, totabl| 
            qry  << "#{img}, "
            vals << "#{totabl}, " 
          }
          qry.chomp!(", ")
          vals.chomp!(", ")
          Puppet.debug(qry)
          Puppet.debug(vals)
          othertbls = @@columns.keys
          othertbls.delete("image")
          if (othertbls.length > 0)
            qry << ") SELECT NULL, "
            qry << vals

            qry << " FROM #{othertbls.join(", ")}"
            qry << " WHERE"
            othertbls.each { |tbl|
              @@columns[tbl].each { |col, param|
                if @@ensurestates.include?(param) then
                  if resource[:ensure] == param then
                    qry << " #{tbl}.#{col} = '1' AND"
                  else
                    qry << " #{tbl}.#{col} = '0' AND"
                  end
                elsif @@tinyintbools.include?(param) then
                  if resource[param] == param then
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
          Puppet.debug(qry)

          qry << "; "
          qry << "INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename) "
          qry <<                    "VALUES (NULL, '#{imageid}', '1', '1', NOW(), '1', '#{resource[:name]}' ); "
          qry << "INSERT INTO resource (id, resourcetypeid, subid) VALUES (NULL, '13', '#{imageid}');"

       	  Puppet.debug(qry)

          cmd_list = @@cmd_base + [ qry ]
          begin
            Puppet.debug(cmd_list.join(" "))
            mysql(cmd_list)
          rescue Puppet::ExecutionFailure => e
            raise Puppet::Error, "mysql #{cmd_list} failed to run: #{e}"
          end
        else
          # change existing definition
          qry = "UPDATE #{@@tbls.join(", ")} SET"
          Puppet.debug(qry)
          @@columns["image"].each { |col, param|
            if @@ensurestates.include?(param) then
              if resource[:ensure] == param then
                qry << " image.#{col}='1',"
              else
                qry << " image.#{col}='0',"
              end
            elsif @@tinyintbools.include?(param) then
              if resource[param] == param then
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
          Puppet.debug(qry)
          @@wheres.each { |img, totabl|
            qry << " #{img}=#{totabl},"
          }
          qry.chomp!(",")
          Puppet.debug(qry)
          othertbls = @@columns.keys
          othertbls.delete("image")
          if (othertbls.length > 0)
            qry << " WHERE"
            othertbls.each { |tbl| 
              @@columns[tbl].each { |col, param|
                if @@ensurestates.include?(param) then
                  if resource[:ensure] == param then
                    qry << " #{tbl}.#{col}='1' AND"
                  else
                    qry << " #{tbl}.#{col}='0' AND"
                  end
                elsif @@tinyintbools.include?(param) then
                  if resource[param] == param then
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
          Puppet.debug(qry)

          cmd_list = @@cmd_base + [ qry ]
          begin
            Puppet.debug(cmd_list.join(" "))
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

