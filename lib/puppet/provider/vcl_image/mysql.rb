require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vclresource'))
Puppet::Type.type(:vcl_image).provide(:mysql, :parent => Puppet::Provider::Vclresource) do

  def self.resourcetype 
    "image"
  end
  def self.maintbl 
    "image"
  end
  def self.columns 
    {
      "image"     => { 
        "name"          => [ :name, 		:string   ],
        "prettyname"    => [ :prettyname, 	:string   ],
        "minram"        => [ :minram, 		:numeric  ],
        "minprocnumber" => [ :minprocnumber, 	:numeric  ],
        "minprocspeed"  => [ :minprocspeed, 	:numeric  ],
        "minnetwork"    => [ :minnetwork, 	:numeric  ],
        "maxconcurrent" => [ :maxconcurrent, 	:numeric  ],
        "reloadtime"    => [ :reloadtime, 	:numeric  ],
        "deleted"       => [ :deleted, 		:tinybool ],
        "test"          => [ :test, 		:tinybool ],
        "forcheckout"   => [ :forcheckout, 	:tinybool ],
        "project"       => [ :project, 		:string   ],
        "size"          => [ :size, 		:numeric  ],
        "architecture"  => [ :architecture, 	:string   ],
        "description"   => [ :description, 	:string   ],
        "usage"         => [ :usage, 		:string   ],
      },
      "OS"        => { "name" => [ :os, 	:string   ], },
      "platform"  => { "name" => [ :platform, 	:string   ], },
    }
  end
  def self.foreign_keys 
    { 
      "OS"        => {
        "name" => [ "image.osid",           "OS.id"       ],
      },
      "platform"  => {
        "name" => [ "image.platformid",  "platform.id" ],
      },
    }
  end
    
  mk_resource_methods

  def flush
    if (resource[:deleted] == :true) then
      qry = "UPDATE imagerevision, image SET deleted=1, datedeleted=NOW() WHERE imagerevision.imageid=image.id AND image.name='#{resource[:name]}' AND imagerevision.deleted!=1"
      self.class.runQuery(qry)
    end
    
    super
    
    if (@property_flush[:ensure] == :absent) then
      # remove rows 
      qry = "DELETE FROM imagerevision WHERE imageid NOT IN (SELECT id FROM image)"
      self.class.runQuery(qry)
    else 
      if (@property_flush[:ensure] == :present) then
        qry =  "INSERT INTO imagerevision (id, imageid, revision, userid, datecreated, production, imagename) "
        qry <<                    "SELECT NULL, image.id, '1', '1', NOW(), '1', '#{resource[:name]}' FROM image WHERE image.name='#{resource[:name]}'"
        self.class.runQuery(qry)
      end
    end
  end
end

