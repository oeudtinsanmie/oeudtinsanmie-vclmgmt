require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vclresource'))
Puppet::Type.type(:vcl_image).provide(:mysql, :parent => Puppet::Provider::Vclresource) do

  @maintbl = "image"
  @columns = {
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
  @wheres = { 
    "image.osid" => "OS.id", 
    "image.platformid" => "platform.id" 
  }
  @tinyintbools = [ :deleted, :test, :forcheckout ]
    
  mk_resource_methods

  def flush
    super.flush
    if (@property_flush and @property_flush[:ensure] == :absent)
      # remove rows 
      qry = "DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image)"
      runQuery(qry)
    else 
      if (@property_flush and @property_flush[:ensure] == :present)
        qry =  "INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename) "
        qry <<                    "SELECT NULL, image.id, '1', '1', NOW(), '1', '#{resource[:name]}' FROM image WHERE image.name='#{resource[:name]}'"
        runQuery(qry)
      end
      if @property_flush[:deleted] then
        qry << " UPDATE imagerevision SET deleted = '1', datedeleted = NOW() WHERE imageid = (SELECT id FROM image WHERE name = '#{resource[:name]}'); "
   	  end
   	end
  end
end

