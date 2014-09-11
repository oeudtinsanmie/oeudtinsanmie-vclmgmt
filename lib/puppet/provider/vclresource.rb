require 'set'
class Puppet::Provider::Vclresource < Puppet::Provider
  
  initvars
  commands :mysql => '/usr/bin/mysql'
  
  def initialize(value={})
    super(value)
    @property_flush = {}
  end
  
  def self.namevar
    "name"
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
    frm = ""
    
    if (foreign_keys.empty?) then
      columns.keys.each { |tbl|
        columns[tbl].each { |col, param|
          qry << "#{tbl}.#{col}, "
        }
      }
      qry << "GROUP_CONCAT(resourcegroup.name SEPARATOR ',') FROM #{maintbl}, resource, resourcegroupmembers, resourcegroup, resourcetype WHERE resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{resourcetype}' AND resource.subid=#{maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid GROUP BY #{maintbl}.id"
    else
      columns[maintbl].each { |col, param|
        qry << "vclrsc.#{col}, "
      }
      othertbls = columns.keys
      othertbls.delete(maintbl)
      othertbls.each { |tbl|
        columns[tbl].each { |col, param|
          qry << "#{tbl}.#{col}, "
        }
      }
      qry <<  "vclrsc.groups FROM (SELECT #{maintbl}.*, GROUP_CONCAT(resourcegroup.name SEPARATOR ',') as groups FROM #{maintbl}, resource, resourcegroupmembers, resourcegroup, resourcetype WHERE resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{resourcetype}' AND resource.subid=#{maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid group by #{maintbl}.id) as vclrsc"

      foreign_keys.each { |tbl, lnks|
        if (lnks.empty?) then 
          raise Puppet::DevError, "Link missing foreign keys for #{tbl} in foreign_keys variable of vclresource child provider"
        end
        qry << " LEFT JOIN #{tbl} ON ("
        lnks.each { |col, lnk|
          frmtbl, frmcol = lnk[0].split('.')
          if (frmtbl == maintbl)
            qry << "vclrsc.#{frmcol}=#{lnk[1]} AND"
          else
            qry << "#{lnk[0]}=#{lnk[1]} AND"
          end
        }
        qry.chomp!(" AND")
        qry << ")"
      }
    end
    
    runQuery(qry).split("\n")
  end
  
  def self.make_hash (obj_str)
    if (obj_str == nil) then
      return {}
    end
    
    hash_list = obj_str.split("\t")
    
    inst_hash = {}
    
    inst_hash[:ensure] = :present
    i = 0
    columns.keys.each { |tbl|
      columns[tbl].each { |col, param|
        if (hash_list[i].include? ",") then 
          inst_hash[param[0]] = hash_list[i].split(",")
        else
          if (param[1] == :tinybool) then
            if (hash_list[i] == '1') then
              inst_hash[param[0]] = :true
            else
              inst_hash[param[0]] = :false
            end
          else
            inst_hash[param[0]] = hash_list[i].strip
          end
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
  
  def paramVal (param)
    if (resource[param[0]] == nil) then
      return "NULL"
    end
    case param[1]
      when :tinybool
        if (resource[param[0]] == :true) then
          1
        else
          0
        end
      when :string
        if (resource[param[0]].is_a?(Array)) then 
          "'#{resource[param[0]].join(',')}'"
        else
          "'#{resource[param[0]]}'"
        end 
      when :numeric
        resource[param[0]]
      else
        raise Puppet::DevError, "Unknown parameter type: #{param[2]}"
    end
  end
  
  def self.runQuery (qry)
    puts qry
    begin
      cmd_list = cmd_base + [ qry ]
      output = mysql(cmd_list).strip
    rescue Puppet::ExecutionFailure => e
      raise Puppet::DevError, "mysql #{cmd_list.join(' ')} had an error -> #{e}"
    end
    output
  end
  
  def insertGroupMembersQry
    qry = "INSERT INTO resourcegroupmembers (resourceid, resourcegroupid) SELECT resource.id, resourcegroup.id FROM resourcegroup, resource, #{self.class.maintbl} WHERE #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}' AND #{self.class.maintbl}.id=resource.subid"
    if (resource[:groups].is_a?(Array)) then
      if (resource[:groups].length > 1) then 
        qry << " AND ("
        resource[:groups].each { |group|
          qry << "resourcegroup.name='#{group}' OR "
        }
        qry.chomp!(" OR ")
        qry << ")"
      else
        qry << " AND resourcegroup.name='#{resource[:groups][0]}'"
      end
    else
      qry << " AND resourcegroup.name='#{resource[:groups]}'"
    end
    qry
  end
  
  def flush
    Puppet.debug "Flushing #{resource[:name]}"
    if (@property_flush[:ensure] === :absent) then
      # remove rows
      Puppet.debug "Deleting #{resource[:name]}"
      qry =  "DELETE FROM #{self.class.maintbl} WHERE #{self.class.namevar} = '#{resource[:name]}'"
      self.class.runQuery(qry)
      qry = "DELETE FROM resource WHERE resource.resourcetypeid IN (SELECT resourcetype.id FROM resourcetype WHERE resourcetype.name='#{self.class.resourcetype}' ) AND resource.subid NOT IN (SELECT id FROM #{self.class.maintbl})"
      self.class.runQuery(qry)
      qry = "DELETE FROM resourcegroupmembers WHERE resourceid NOT IN (SELECT id FROM resource)"
      self.class.runQuery(qry)
      
    elsif (@property_flush[:ensure] === :present) then
      # add resource
      Puppet.debug "Adding new VCL Resource: #{resource[:name]}"
      qry = "INSERT INTO #{self.class.maintbl} (id, "
      vals = ""
      frm = Set[]
      whr = " WHERE"
      
      self.class.columns[self.class.maintbl].each { |col, param|
        qry  << "#{self.class.maintbl}.#{col}, "
        vals << "#{paramVal(param)}, "
      }
      
      othertbls = self.class.columns.keys
      othertbls.delete(self.class.maintbl)
      if (othertbls.length > 0) then
        othertbls.each { |tbl|
          self.class.columns[tbl].each { |col, param|
            if (resource[param[0]] == nil) then
              qry  << " #{self.class.foreign_keys[tbl][col][0]},"
              vals << "NULL,"
            else
              qry  << " #{self.class.foreign_keys[tbl][col][0]},"
              vals << " #{self.class.foreign_keys[tbl][col][1]},"
              whr  << " #{tbl}.#{col}=#{paramVal(param)} AND"
              frm += [ tbl ]
            end
          }
        }
      end
      
      qry.chomp!(",")
      vals.chomp!(",")
      if (frm.empty?) then
        qry << ") VALUES (NULL, "
        qry << vals
        qry << ")"
      else
        whr.chomp!(" AND")
        
        qry << ") SELECT NULL, "
        qry << vals
        qry << " FROM #{frm.to_a.join(', ')}"
        qry << whr
      end  
      
      self.class.runQuery(qry)
      
      qry = "INSERT INTO resource (id, resourcetypeid, subid) SELECT NULL, resourcetype.id, #{self.class.maintbl}.id FROM resourcetype, #{self.class.maintbl} WHERE resourcetype.name='#{self.class.resourcetype}' AND #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"

      Puppet.debug "Adding recource entry for #{resource[:name]}"
      self.class.runQuery(qry)
      
      self.class.runQuery(insertGroupMembersQry)
      
    else
      # change existing definition
      Puppet.debug "Updating records for #{resource[:name]}"
      qry = "UPDATE #{self.class.columns.keys.join(", ")} SET"
      self.class.columns[self.class.maintbl].each { |col, param|
        qry << " #{self.class.maintbl}.#{col}=#{paramVal(param)},"
      }
      
      othertbls = self.class.columns.keys
      othertbls.delete(self.class.maintbl)
      if (othertbls.length > 0) then
        whr = ""
        othertbls.each { |tbl|
          self.class.columns[tbl].each { |col, param|
            if (resource[param[0]] == nil) then
              qry << " #{self.class.foreign_keys[tbl][col][0]}=NULL"
            else
              qry << " #{self.class.foreign_keys[tbl][col][0]}=#{self.class.foreign_keys[tbl][col][1]},"
              whr << " #{tbl}.#{col}=#{paramVal(param)} AND"
            end
          }
        }
        whr << " #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"
      else
        whr = " WHERE  #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"
      end
      
      qry.chomp!(",")
      qry << " WHERE"
      qry << whr  
      
      self.class.runQuery(qry)
      
      Puppet.debug "Refreshing VCL Resource groups for #{resource[:name]}"
      qry =  "DELETE FROM resourcegroupmembers WHERE resourceid IN (SELECT resource.id FROM resource, #{self.class.maintbl} WHERE #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}' AND #{self.class.maintbl}.id=resource.subid); "
      qry << insertGroupMembersQry
      self.class.runQuery(qry)
      Puppet.debug "Done"
    end
  end
end
