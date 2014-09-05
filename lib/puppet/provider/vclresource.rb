class Puppet::Provider::Vclresource < Puppet::Provider
  
  initvars
  commands :mysql => '/usr/bin/mysql'
  
  def initialize(value={})
    super(value)
    @property_flush = {}
  end
  
  def self.vcldb
    vcldconf = File.new("/etc/vcl/vcld.conf", "r")
    while(line = vcldconf.gets)
      if (line.start_with? "database") then
        return line.split('=').at(1).strip.delete("'")
      end
    end
  end
  
  def self.cmd_base
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      cmd_base = [ "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf" ]
    else
      cmd_base = []
    end 
    cmd_base += [ "-D", vcldb, "-NBe" ]
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
    
    @columns.keys.each { |tbl|
      @columns[tbl].each { |col, param|
        qry << "#{tbl}.#{col}, "
      }
    }
    
    qry << "GROUP_CONCAT(resourcegroup.name SEPARATOR ',') FROM #{@columns.keys.join(", ")}, resource, resourcegroup, resourcegroupmembers"
    qry << " WHERE"
    @wheres.each { |key, val|
      qry << " #{key}=#{val} AND"
    }
    
    qry << " resource.subid=#{@maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid GROUP BY image.id"
    
    runQuery(qry.split("\n"))
  end
  
  def self.make_hash (obj_str)
    if (obj_str == nil) then
      return {}
    end
    
    hash_list = obj_str.split("\t")
    
    inst_hash = {}
    
    inst_hash[:ensure] = :present
    i = 0
    @columns.keys.each { |tbl|
      @columns[tbl].each { |col, param|
        if (hash_list[i].include? ",") then
          inst_hash[param] = hash_list[i].strip.split(",")
        else
          inst_hash[param] = hash_list[i].strip
        end
        i = i+1
      }
    }
    if (hash_list[i].include? ",") then
      inst_hash[:groups] = hash_list[i].strip.split(",")
    else
      inst_hash[:groups] = hash_list[i].strip
    end
    
    inst_hash.merge!(inst_hash) { |key, oldval, val| val == 'NULL' ? nil : val }
    @tinyintbools.each { |key|
      if (inst_hash[key] == '1') then
        inst_hash[key] = :true
      else
        inst_hash[key] = :false
      end
    }
    
    Puppet::Util::symbolizehash(inst_hash)
  end
  
  def self.prefetch (resources) 
    instances.each { |prov|
      if (resource = resources[prov.name]) then
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
    if (@tinyintbools.include?(param)) then
      if (resource[param] == :true) then
        return "'1'"
      else
        return "'0'"
      end
    elsif (resource[param] == nil) then
      return "NULL"
    end
    "'#{resource[param]}'" 
  end
  
  def self.runQuery (qry)
    begin
      cmd_list = cmd_base + [ qry ]
      output = mysql(cmd_list).strip
    rescue Puppet::ExecutionFailure => e
      raise Puppet::DevError, "mysql #{cmd_list.join(' ')} had an error -> #{e}"
    end
    output
  end
  
  def insertGroupMembersQry
    qry = "INSERT INTO resourcegroupmembers (resourceid, resourcegroupid) SELECT resource.id, resourcegroup.id FROM resourcegroup, resource, #{@maintbl} WHERE #{@maintbl}.name='#{resource[:name]}' AND #{@maintbl}.id=resource.subid"
    if (resource[:groups].is_a?(Array)) then
      qry << " AND ("
      resource[:groups].each { |group|
        qry << "resourcegroup.name='#{group}' OR "
      }
      qry.chomp!(" OR ")
      qry << ")"
    else
      qry << " AND resourcegroup.name='#{resource[:groups]}'"
    end
    qry
  end
  
  def flush
    if (@property_flush[:ensure] == :absent) then
      # remove rows
      qry =  "DELETE FROM #{maintbl} WHERE name = '#{resource[:name]}'; "
      qry << "DELETE FROM resource WHERE resourcetypeid = resourcetype.id AND resourcetype.name='#{@resourcetype}' AND resource.subid NOT IN (SELECT d FROM #{@maintbl}); "
      qry << "DELETE FROM resourcegroupmembers WHERE resourceid NOT IN (SELECT id FROM resource)"
      runQuery(qry)
      
    elsif (@property_flush[:ensure == :present]) then
      # add resource
      qry = "INSERT INTO #{@maintbl} (id, "
      vals = ""
      @columns[@maintbl].each { |col, param|
        qry  << "#{@maintbl}.#{col}, "
        vals << "#{totabl}, "
      }
      @wheres.each { |linkid, totabl|
        qry  << "#{linkid}, "
        vals << "#{totabl}, "
      }
      
      qry.chomp!(", ")
      vals.chomp!(", ")
      othertbls = @columns.keys
      othertbls.delete(@maintbl)
      if (othertbls.length > 0) then
        qry << ") SELECT NULL, "
        qry << vals 
        
        qry << " FROM #{othertbls.join(", ")} WHERE"
        othertbls.each { |tbl|
          @columns[tbl].each { |col, param|
            qry << " #{tbl}.#{col}=#{paramVal(param)} AND"
          }
        }
        qry.chomp!(" AND")
      else
        qry << ") VALUES (NULL, "
        qry << vals
        qry << ")"
      end
      runQuery(qry)
      
      qry = "INSERT INTO resource (id, resourcetypeid, subid) SELECT NULL, resourcetype.id, #{@maintbl}.id FROM resourcetype, #{@maintbl} WHERE resourcetype.name='#{@resourcetype}' AND #{@maintbl}.name='#{resource[:name]}'"
      runQuery(qry)
      
      runQuery(insertGroupMembersQry)
      
    else
      # change existing definition
      qry = "UPDATE #{columns.keys.join(", ")} SET"
      @columns[@maintbl].each { |col, param|
        qry << " #{@maintbl}.#{col}=#{paramVal(param)}"
      }
      @wheres.each { |linkid, totabl|
        qry << " #{linkid}=#{totabl}"
      }
      qry.chomp!(",")
      othertbls = @columns.keys
      othertbls.delete(@maintbl)
      if (othertbls.length > 0) then
        qry << " WHERE"
        othertbls.each { |tbl|
          @columns[tbl].each { |col, param|
            qry << " #{tbl}.#{col}=#{paramVal(param)} AND"
          }
        }
        qry <<        " #{@maintbl}.name='#{resource[:name]}'"
      else
        qry << " WHERE  #{@maintbl}.name='#{resource[:name]}'"
      end
      runQuery(qry)
      
      qry =  "DELETE FROM resourcegroupmembers WHERE resourceid=resource.id AND #{@maintbl}.name='#{resource[:name]}' AND #{@maintbl}.id=resource.subid; "
      qry << insertGroupMembersQry
      runQuery(qry)
    end
  end
end