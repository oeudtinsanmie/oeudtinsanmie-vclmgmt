require 'set'
require 'pp'
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
  
  def self.appendForeign(cols, tbl, qry) 
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if col == :recurse then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        qry = appendForeign(cols[tbl], col, qry)
      else
        qry << "#{tbl}.#{col}, "
      end
    }
    puts "#{qry}\n\n"
    qry
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
        qry = appendForeign(columns, tbl, qry)
      }
      qry <<  "vclrsc.groups FROM (SELECT #{maintbl}.*, GROUP_CONCAT(resourcegroup.name SEPARATOR ',') as groups FROM #{maintbl}, resource, resourcegroupmembers, resourcegroup, resourcetype WHERE resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{resourcetype}' AND resource.subid=#{maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid group by #{maintbl}.id) as vclrsc"

      puts "Foreign Keys"
      puts "#{qry}\n\n"
      foreign_keys.each { |tbl, lnks|
        qry = joinForeignKeys(qry, tbl, lnks)
      }
      puts "#{qry}\n\n"
    end
    
    puts "QUERY: "
    puts "#{qry}\n\n"
    runQuery(qry).split("\n")
  end
  
  def self.joinLink(lnk, tbl, as)
    pp [lnk, tbl, as]
    frmtbl, frmcol = lnk[0].split('.')
    if (frmtbl == maintbl) then
      from = "vclrsc.#{frmcol}"
    else
      from = lnk[0]
    end
    totbl, tocol = lnk[1].split('.')
    if (as and totbl == tbl) then
      to = "#{as}.#{tocol}"
    else
      to = lnk[1]
    end
    "#{from}=#{to}"
  end
  
  def self.protectedHashKeys
    [ :recurse, :step, :as ]
  end
  
  def self.joinForeignKeys(qry, tbl, lnks) 
    if tbl == :recurse then
      # do nothing
      return qry
    end
    if (lnks.empty?) then 
      raise Puppet::DevError, "Link missing foreign keys for #{tbl} in foreign_keys variable of vclresource child provider"
    end
    if lnks[:recurse] == nil then
      lnks[:recurse] = []
    end
    if lnks[:as] == nil then
      lnks[:as] = {}
    end
    lnks.each { |col, lnk|
      unless protectedHashKeys.include? col or lnks[:recurse].include? col
        qry << " LEFT JOIN #{tbl}"
        qry << " AS #{lnks[:as][col]}" if lnks[:as][col]
        qry << " ON " 
        puts "#{qry}\n\n"
        qry << joinLink(lnk, tbl, lnks[:as][col]) 
      end
    }
    
    lnks[:recurse].each { |newtbl|
      qry << " LEFT JOIN #{tbl}"
      qry << " AS #{lnks[:as][newtbl]}" if lnks[:as][newtbl]
      qry << " ON "
      qry << joinLink(lnks[newtbl][:step], tbl, lnks[:as][newtbl])
      puts "#{qry}\n\n"
      qry = joinForeignKeys(qry, newtbl, lnks[newtbl])
    }
    qry
  end
  
  def self.make_hash (obj_str)
    if (obj_str == nil) then
      return {}
    end
    
    hash_list = obj_str.split("\t")
    
    inst_hash = {}
    
    inst_hash[:ensure] = :present
    i = 0
    othertbls = columns.keys
    othertbls.delete(maintbl)
    columns[maintbl].each { |col, param|
      inst_hash[param[0]] = hashitem(hash_list[i], param)
      i = i+1
    }
    othertbls.each { |tbl|
      inst_hash, i = hashForeign(columns, tbl, inst_hash, i)
    }
    if (hash_list[i].include? ",") then
      inst_hash[:groups] = hash_list[i].strip.split(",")
    else
      inst_hash[:groups] = hash_list[i].strip
    end
    
    inst_hash.merge!(inst_hash) { |key, oldval, val| val == 'NULL' ? nil : val }

#    pp inst_hash
    Puppet::Util::symbolizehash(inst_hash)
  end
  
  def self.hashForeign(cols, tbl, inst_hash, i) 
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if col == :recurse then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        inst_hash, i = hashForeign(tbl, col, inst_hash, i)
      else
        inst_hash[param[0]] = hashitem(hash_list[i], param)
        i = i+1
      end
    }
    [ inst_hash, i ]
  end
  
  def self.hashitem (item, param)
    if (item.include? ",") then
      item.split(",")
    elsif (param[1] == :tinybool) then
      if (item == '1') then
        :true
      else
        :false
      end
    else
      item
    end
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
#    puts qry
    begin
      cmd_list = cmd_base + [ qry ]
      output = mysql(cmd_list).strip
    rescue Puppet::ExecutionFailure => e
      raise Puppet::DevError, "mysql #{cmd_list.join(' ')} had an error -> #{e}"
    end
    output
  end
  
  def insertGroupMembersQry
    qry = "INSERT INTO resourcegroupmembers (resourceid, resourcegroupid) SELECT resource.id, resourcegroup.id FROM resourcegroup, resource, resourcetype, #{self.class.maintbl} WHERE #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}' AND #{self.class.maintbl}.id=resource.subid AND resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{self.class.resourcetype}'"
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
  
  def fillCreateForeign(cols, keys, main, tbl, qry, vals, whr, frm)
    xtraQrys = []
    if tbl == :recurse then
      # do nothing
      return [ qry, vals, whr, frm, xtraQrys ]
    end
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if col == :recurse then
        # do nothing
      elsif cols[:recurse].include? col then
        
        if keys[tbl][col][:step][0].split('.')[0] == main then
          newqry = makeCreateQry(cols[tbl], keys[tbl], tbl)
          xtraQrys += [ newqry ]
        else
          qry, vals, whr, frm, xtra = fillCreateForeign(cols[tbl], keys[tbl], tbl, col, qry, vals, whr, frm)
          xtraQrys += xtra
          whr << " #{keys[tbl][col][:step][0]}=#{keys[tbl][col][:step][1]} AND"
          frm += [ tbl ]
        end
      else
        if (resource[param[0]] == nil) then
          # do nothing
        elsif (resource[param[0]] == :none) then
          qry  << " #{keys[tbl][col][0]},"
          vals << "NULL,"
        else
          qry  << " #{keys[tbl][col][0]},"
          vals << " #{keys[tbl][col][1]},"
          whr  << " #{tbl}.#{col}=#{paramVal(param)} AND"
          frm += [ tbl ]
        end
      end
    }
    [ qry, vals, whr, frm, xtraQrys ]
  end
  
  def makeCreateQry(cols, keys, main)
    qry = "INSERT INTO #{main} (id, "
    vals = ""
    frm = Set[]
    whr = " WHERE"
  
    cols[main].each { |col, param|
      qry  << "#{main}.#{col}, "
      vals << "#{paramVal(param)}, "
    }
  
    othertbls = cols.keys
    othertbls.delete(main)
    if (othertbls.length > 0) then
      othertbls.each { |tbl|
        qry, vals, whr, frm, xtraQrys = fillCreateForeign(cols, keys, main, tbl, qry, vals, whr, frm)
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
    unless xtraQrys.empty?
      qry << "; "
      qry << xtraQrys.join("; ")
    end
    qry 
  end
  
  def deleteForeignEntries(keys, main)
    keys.each { |tbl, lnks|
      if (lnks.empty?) then 
        raise Puppet::DevError, "Link missing foreign keys for #{tbl} in foreign_keys variable of vclresource child provider"
      end
      if tbl == :recurse then
        # do nothing
      else
        if lnks[:recurse] == nil then
          lnks[:recurse] = []
        end
        lnks.each { |col, lnk|
          if lnks[:recurse].include? col then 
            if keys[tbl][col][:step][0].split('.')[0] == main then
              qry = "DELETE FROM #{tbl} WHERE #{keys[tbl][col][:step][1]} NOT IN (SELECT #{keys[tbl][col][:step][0].split('.')[1]} FROM #{main})"
              self.class.runQuery(qry)
            end
            deleteForeignEntries(lnks, tbl)
          end
        }
      end
    }
  end
  
  def flush
    Puppet.debug "Flushing #{resource[:name]}"
    if (@property_flush[:ensure] != nil) then
      # remove rows
      Puppet.debug "Deleting #{resource[:name]}"
      qry =  "DELETE FROM #{self.class.maintbl} WHERE #{self.class.namevar} = '#{resource[:name]}'"
      self.class.runQuery(qry)
      qry = "DELETE FROM resource WHERE resource.resourcetypeid IN (SELECT resourcetype.id FROM resourcetype WHERE resourcetype.name='#{self.class.resourcetype}' ) AND resource.subid NOT IN (SELECT id FROM #{self.class.maintbl})"
      self.class.runQuery(qry)
      qry = "DELETE FROM resourcegroupmembers WHERE resourceid NOT IN (SELECT id FROM resource)"
      self.class.runQuery(qry)
      deleteForeignEntries(self.class.foreign_keys, self.class.maintbl)
      
      if (@property_flush[:ensure] == :present) then
        # add resource
        Puppet.debug "Adding new VCL Resource: #{resource[:name]}"
        qry = makeCreateQry(self.class.columns, self.class.foreign_keys, self.class.maintbl)
        self.class.runQuery(qry)
      
        qry = "INSERT INTO resource (id, resourcetypeid, subid) SELECT NULL, resourcetype.id, #{self.class.maintbl}.id FROM resourcetype, #{self.class.maintbl} WHERE resourcetype.name='#{self.class.resourcetype}' AND #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"

        Puppet.debug "Adding recource entry for #{resource[:name]}"
        self.class.runQuery(qry)
      
        self.class.runQuery(insertGroupMembersQry)
      end
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
          qry, whr = fillUpdateForeign(self.class.columns, self.class.foreign_keys, tbl, qry, whr)
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
      qry =  "DELETE FROM resourcegroupmembers WHERE resourceid IN (SELECT resource.id FROM resource, resourcetype, #{self.class.maintbl} WHERE #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}' AND #{self.class.maintbl}.id=resource.subid AND resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{self.class.resourcetype}'); "
      qry << insertGroupMembersQry
      self.class.runQuery(qry)
      Puppet.debug "Done"
    end
  end
  
  def fillUpdateForeign(cols, keys, tbl, qry, whr)
    if tbl == :recurse then
      # do nothing
      return [ qry, whr ]
    end
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if col == :recurse then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        qry, whr = fillUpdateForeign(cols[tbl], keys[tbl], col, qry, whr)
        whr << " #{keys[tbl][col][:step][0]}=#{keys[tbl][col][:step][1]} AND"
      else
        if (resource[param[0]] == nil) then
          # do nothing
        elsif (resource[param[0]] == :none) then
          qry << " #{keys[tbl][col][0]}=NULL"
        else
          qry << " #{keys[tbl][col][0]}=#{keys[tbl][col][1]},"
          whr << " #{tbl}.#{col}=#{paramVal(param)} AND"
        end
      end
    }
    [ qry, whr ]
  end
end
