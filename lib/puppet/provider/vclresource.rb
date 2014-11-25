require 'set'
require 'pp'
class Puppet::Provider::Vclresource < Puppet::Provider
  
  initvars
  commands :mysql => '/usr/bin/mysql'
  
  def initialize(value={})
    super(value)
    @property_flush = new Hash(value)
    @property_flush.delete(:ensure)
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
      if protectedHashKeys.include? col then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        qry = appendForeign(cols[tbl], col, qry)
      else
        qry << "#{tbl}.#{col}, "
      end
    }
    qry
  end
  
  def self.list_obj
    qry = "SELECT "
    frm = ""
    
    if (foreign_keys.empty?) then
      columns.keys.each { |tbl|
        columns[tbl].each { |col, param|
          qry << "#{tbl}.#{col}, " unless protectedHashKeys.include? col
        }
      }
      qry << "GROUP_CONCAT(resourcegroup.name SEPARATOR ',') FROM #{maintbl}, resource, resourcegroupmembers, resourcegroup, resourcetype WHERE resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{resourcetype}' AND resource.subid=#{maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid GROUP BY #{maintbl}.id"
    else
      columns[maintbl].each { |col, param|
        qry << "vclrsc.#{col}, " unless protectedHashKeys.include? col
      }
      othertbls = columns.keys
      othertbls.delete(maintbl)
      othertbls.each { |tbl|
        qry = appendForeign(columns, tbl, qry)
      }
      qry <<  "vclrsc.groups FROM (SELECT #{maintbl}.*, GROUP_CONCAT(resourcegroup.name SEPARATOR ',') as groups FROM #{maintbl}, resource, resourcegroupmembers, resourcegroup, resourcetype WHERE resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{resourcetype}' AND resource.subid=#{maintbl}.id AND resourcegroupmembers.resourceid=resource.id AND resourcegroup.id=resourcegroupmembers.resourcegroupid group by #{maintbl}.id) as vclrsc"

      foreign_keys.each { |tbl, lnks|
        qry = joinForeignKeys(qry, tbl, nil, nil, lnks)
      }
    end
    
    runQuery(qry).split("\n")
  end
  
  def self.joinLink(lnk, tbl, as, parent, asparent)
    frmtbl, frmcol = lnk[0].split('.')
    if (frmtbl == maintbl) then
      from = "vclrsc.#{frmcol}"
    elsif (asparent and frmtbl == parent) then
      from = "#{asparent}.#{frmcol}"
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
    [ :recurse, :step, :as, :namevar ]
  end
  
  def self.joinForeignKeys(qry, tbl, parent, as, lnks) 
    if protectedHashKeys.include? tbl then
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
        qry << joinLink(lnk, tbl, lnks[:as][col], parent, as) 
      end
    }
    
    lnks[:recurse].each { |newtbl|
      qry << " LEFT JOIN #{tbl}"
      qry << " AS #{lnks[:as][newtbl]}" if lnks[:as][newtbl]
      qry << " ON "
      qry << joinLink(lnks[newtbl][:step], tbl, lnks[:as][newtbl], parent, as)
      qry = joinForeignKeys(qry, newtbl, tbl, lnks[:as][newtbl], lnks[newtbl])
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
      inst_hash, i = hashForeign(columns, tbl, inst_hash, hash_list, i)
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
  
  def self.hashForeign(cols, tbl, inst_hash, hash_list, i) 
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if protectedHashKeys.include? col then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        inst_hash, i = hashForeign(cols[tbl], col, inst_hash, hash_list, i)
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
#    Puppet.debug qry
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
  
  def fillCreateForeign(cols, keys, main, tbl)
    xtraQrys = []
    if self.class.protectedHashKeys.include? tbl then
      # do nothing
      return xtraQrys
    end
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if col == :recurse then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        
        if keys[tbl][:as] == nil then 
          keys[tbl][:as] = []
        end
        unless keys[tbl][:as].include? col 
          newqry = makeXtraQry(cols, keys[tbl], tbl, col)
          xtraQrys += newqry
        end
      end
    }
    xtraQrys
  end
  
  def makeXtraQry(cols, keys, main, tbl)
    qry = "INSERT INTO #{main} (id,"
    vals = ""
    frm = Set[]
    whr = " WHERE"
    
    doMakeQry = false
    keys[tbl].each { | col, param | 
       unless self.class.protectedHashKeys.include? col 
         val = resource[cols[main][tbl][col][0]]
         oldval = @property_flush[cols[main][tbl][col][0]]
         if (oldval == nil or oldval == :none) and val != nil and val != :none then
            doMakeQry = true 
         end
       end
    }
    unless doMakeQry == true
      return [] 
    end
  
    qry  << keys[tbl][:step][1].split('.')[1]
    vals << keys[tbl][:step][0]
    steptbl = keys[tbl][:step][0].split('.')[0]
    frm += [ steptbl ]
    name = cols[steptbl][:namevar]
    whr << " #{steptbl}.#{name}=#{paramVal(cols[steptbl][name])}"
    
    qry << ") SELECT NULL,"
    qry << vals 
    qry << " FROM #{frm.to_a.join(', ')}"
    qry << whr
    [ qry ] 
  end
  
#  def makeCreateQry(cols, keys, main)
#    qry = "INSERT INTO #{main} (id,"
#    vals = ""
#    frm = Set[]
#    whr = " WHERE"
#    xtraQrys = []
#  
#    cols[main].each { |col, param|
#      unless self.class.protectedHashKeys.include? col
#        qry  << " #{main}.#{col},"
#        vals << " #{paramVal(param)},"
#      end
#    }
#    if cols[:recurse] == nil then
#      cols[:recurse] = []
#    end
#    unless cols[:recurse].include? main
#      othertbls = cols.keys
#      othertbls.delete(main)
#      if (othertbls.length > 0) then
#        othertbls.each { |tbl|
#          xtraQrys += fillCreateForeign(cols, keys, main, tbl)
#        }
#      end
#    end
#  
#    qry.chomp!(",")
#    vals.chomp!(",")
#    if (frm.empty?) then
#      qry << ") VALUES (NULL,"
#      qry << vals
#      qry << ")"
#    else
#      whr.chomp!(" AND")
#    
#      qry << ") SELECT NULL,"
#      qry << vals
#      qry << " FROM #{frm.to_a.join(', ')}"
#      qry << whr
#    end  
#    unless xtraQrys.empty?
#      qry << "; "
#      qry << xtraQrys.join("; ")
#    end
#    qry 
#  end
  
  def deleteForeignEntries(keys, main)
    keys.each { |tbl, lnks|
      if (lnks.empty?) then 
        raise Puppet::DevError, "Link missing foreign keys for #{tbl} in foreign_keys variable of vclresource child provider"
      end
      if self.class.protectedHashKeys.include? tbl then
        # do nothing
      else
        if lnks[:recurse] == nil then
          lnks[:recurse] = []
        end
        lnks.each { |col, lnk|
          if self.class.protectedHashKeys.include? col then
            # do nothing
          elsif lnks[:recurse].include? col then 
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
    pp @resource.to_hash
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
      
      if (@property_flush[:ensure] == :absent) then
        return
      end
      # add resource
      Puppet.debug "Adding new VCL Resource: #{resource[:name]}"
#        qry = makeCreateQry(self.class.columns, self.class.foreign_keys, self.class.maintbl)
      
      qry = "INSERT INTO #{self.class.maintbl} (id,"
      vals = ""
    
      self.class.columns[self.class.maintbl].each { |col, param|
        unless self.class.protectedHashKeys.include? col
          qry  << " #{self.class.maintbl}.#{col},"
          vals << " #{paramVal(param)},"
        end
      }
      qry << ") VALUES (NULL,"
      qry << vals
      qry << ")"
      
      Puppet.debug qry
#        self.class.runQuery(qry)
    
      qry = "INSERT INTO resource (id, resourcetypeid, subid) SELECT NULL, resourcetype.id, #{self.class.maintbl}.id FROM resourcetype, #{self.class.maintbl} WHERE resourcetype.name='#{self.class.resourcetype}' AND #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"

      Puppet.debug "Adding recource entry for #{resource[:name]}"
      Puppet.debug qry
#        self.class.runQuery(qry)

      Puppet.debug insertGroupMembersQry
    
#        self.class.runQuery(insertGroupMembersQry)
    end
    
    xtraQrys = []
    othertbls = self.class.columns.keys
    othertbls.delete(self.class.maintbl)
    if (othertbls.length > 0) then
      othertbls.each { |tbl|
        xtraQrys += fillCreateForeign(cols, keys, main, tbl)
      }
    end
    unless xtraQrys.empty?
      qry = xtraQrys.join("; ")
      Puppet.debug qry
#        self.class.runQuery(qry)
    end
    
    # change existing definition
    Puppet.debug "Updating records for #{resource[:name]}"
    
    qry = ""
    frm = Set[]
    frm += [ self.class.maintbl ]

    self.class.columns[self.class.maintbl].each { |col, param|
      qry << " #{self.class.maintbl}.#{col}=#{paramVal(param)},"
    }
    Puppet.debug qry

    othertbls = self.class.columns.keys
    othertbls.delete(self.class.maintbl)
    if (othertbls.length > 0) then
      whr = ""
      othertbls.each { |tbl|
        qry, whr, frm = fillUpdateForeign(self.class.columns, self.class.foreign_keys, tbl, qry, whr, frm)
        Puppet.debug qry
      }
      whr << " #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"
      Puppet.debug whr
    else
      whr = " WHERE  #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}'"
    end
    
    qry.chomp!(",")
    qry = "UPDATE #{frm.to_a.join(", ")} SET#{qry}"
    
    qry << " WHERE"
    qry << whr  

    self.class.runQuery(qry)
    
    Puppet.debug "Refreshing VCL Resource groups for #{resource[:name]}"
    qry =  "DELETE FROM resourcegroupmembers WHERE resourceid IN (SELECT resource.id FROM resource, resourcetype, #{self.class.maintbl} WHERE #{self.class.maintbl}.#{self.class.namevar}='#{resource[:name]}' AND #{self.class.maintbl}.id=resource.subid AND resource.resourcetypeid=resourcetype.id AND resourcetype.name='#{self.class.resourcetype}'); "
    qry << insertGroupMembersQry
    self.class.runQuery(qry)
    Puppet.debug "Done"
  end
  
  def fillUpdateForeign(cols, keys, tbl, qry, whr, frm)
    if self.class.protectedHashKeys.include? tbl then
      # do nothing
      return [ qry, whr, frm ]
    end
    if cols[tbl][:recurse] == nil then
      cols[tbl][:recurse] = []
    end
    cols[tbl].each { |col, param|
      if self.class.protectedHashKeys.include? col then
        # do nothing
      elsif cols[tbl][:recurse].include? col then
        param.each { |c, p|
          unless resource[p[0]] == :none or resource[p[0]] == nil
            frm += [ col ]
            qry, whr, frm = fillUpdateForeign(cols[tbl], keys[tbl], col, qry, whr, frm)
            whr << " #{keys[tbl][col][:step][0]}=#{keys[tbl][col][:step][1]} AND"
          end
        }
      else
        if (resource[param[0]] == nil) then
          # do nothing
        elsif (resource[param[0]] == :none) then
          qry << " #{keys[tbl][col][0]}=NULL," unless !keys[tbl][col]
        else
          frm += [ tbl ]
          if keys[tbl][col] then
            qry << " #{keys[tbl][col][0]}=#{keys[tbl][col][1]},"
          end
          whr << " #{tbl}.#{col}=#{paramVal(param)} AND"
        end
      end
    }
    [ qry, whr, frm ]
  end
end
