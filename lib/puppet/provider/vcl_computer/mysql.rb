require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vclresource'))
Puppet::Type.type(:vcl_computer).provide(:mysql, :parent => Puppet::Provider::Vclresource) do

  def self.resourcetype 
    "computer"
  end
  def self.maintbl 
    "computer"
  end
  def self.namevar
    "hostname"
  end
  def self.columns 
    {
      "computer"     => { 
        "hostname"          => [ :name, 		    :string   ],
        "RAM"               => [ :ram, 	        :numeric  ],
        "procnumber"        => [ :procnumber,   :numeric  ],
        "procspeed"         => [ :procspeed, 	  :numeric  ],
        "network"           => [ :network, 	    :numeric  ],
        "IPaddress"         => [ :public_ip, 	  :string   ],
        "privateIPaddress"  => [ :private_ip,   :string   ],
        "eth0macaddress"    => [ :private_mac,  :string   ],
        "eth1macaddress"    => [ :public_mac,   :string   ],
        "type"              => [ :type,         :string   ],
        "drivetype"         => [ :drivetype,    :string   ],
        "deleted"           => [ :deleted, 	    :tinybool ],
        "notes"             => [ :notes, 	      :string   ],
        "location"          => [ :location,     :string   ],
        "dsa"               => [ :dsa,          :string   ],
        "dsapub"            => [ :dsapub,       :string   ],
        "rsa"               => [ :rsa,          :string   ],
        "rsapub"            => [ :rsapub,       :string   ],
        "hostpub"           => [ :hostpub,      :string   ],
      },
      "platform"      => { "name"         => [ :platform,       :string   ], },
      "schedule"      => { "name"         => [ :vclschedule,    :string   ], },
      "image"         => { "name"         => [ :image,          :string   ], },
      "imagerevision" => { "revision"     => [ :imagerevision,  :numeric  ], },
      "provisioning"  => { "prettyname"   => [ :provisioning,   :string   ], },
      "vmtype"        => { "name"         => [ :vmtype,         :string   ], },
      "vmhost"        => { 
        :recurse      => [ "computer", "vmprofile", ],
        "computer"    => { "hostname"     => [ :vmhost,         :string   ], },
        "vmprofile"   => { "profilename"  => [ :vmprofile,      :string   ], },
        
        "vmlimit"                         => [ :vmlimit,        :numeric  ],
      },
    }
  end
  def self.foreign_keys 
    { 
      "state"         => {
        "name"        => [ "computer.stateid",          "state.id"          ],
      },
      "platform"      => {
        "name"        => [ "computer.platformid",       "platform.id"       ],
      },
      "schedule"      => {
        "name"        => [ "computer.scheduleid",       "schedule.id"       ],
      },
      "image"         => {
        "name"        => [ "computer.nextimageid",      "image.id"          ],
      },
      "imagerevision" => {
        "revision"    => [ "computer.imagerevisionid",  "imagerevision.id"  ],
      },
      "provisioning"  => {
        "prettyname"  => [ "computer.provisioningid",   "provisioning.id"   ],
      },
      "vmtype"        => {
        "name"        => [ "computer.vmtypeid",         "vmtype.id"         ],
      },
      "vmhost"        => { 
        :recurse      => [ "computer", "vmprofile", ],
        "computer"    => {
          :step => [ "computer.vmhostid",  "vmhost.id"     ],
          "hostname"     => [ "vmhost.computerid", "computer.id" ], 
        },
        "vmprofile"   => { 
          :step => [ "computer.id",    "vmhost.computerid" ],
          "profilename"  => [ "vmhost.profileid", "vmprofile.id" ], 
        },
      },
    }
  end
    
  mk_resource_methods
  
end

