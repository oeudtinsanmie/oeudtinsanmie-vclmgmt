require File.expand_path(File.join(File.dirname(__FILE__), '..', 'vclresource'))
Puppet::Type.type(:vcl_image).provide(:mysql, :parent => Puppet::Provider::Vclresource) do

  def self.resourcetype 
    "computer"
  end
  def self.maintbl 
    "computer"
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
      "state"         => { "name"     => [ :state, 		      :string   ], },
      "platform"      => { "name"     => [ :platform,       :string   ], },
      "schedule"      => { "name"     => [ :schedule,       :string   ], },
      "image"         => { "name"     => [ :image,          :string   ], },
      "imagerevision" => { "name"     => [ :imagerevision,  :string   ], },
      "provisioning"  => { "name"     => [ :provisioning,   :string   ], },
      "vmhost"        => { "name"     => [ :vmhost,         :string   ], },
      "vmtype"        => { "name"     => [ :vmtype,         :string   ], },
    }
  end
  def self.foreign_keys 
    { 
      "state"         => {
        "name" => [ "computer.stateid",          "state.id"          ],
      },
      "platform"      => {
        "name" => [ "computer.platformid",       "platform.id"       ],
      },
      "schedule"      => {
        "name" => [ "computer.scheduleid",       "schedule.id"       ],
      },
      "image"         => {
        "name" => [ "computer.nextimageid",      "image.id"          ],
      },
      "imagerevision" => {
        "name" => [ "computer.imagerevisionid",  "imagerevision.id"  ],
      },
      "provisioning"  => {
        "name" => [ "computer.provisioningid",   "provisioning.id"   ],
      },
      "vmhost"        => {
        "name" => [ "computer.vmhostid",         "vmhost.id"         ],
      },
      "vmtype"        => {
        "name" => [ "computer.vmtypeid",         "vmtype.id"         ],
      },
    }
  end
    
  mk_resource_methods
  
end

