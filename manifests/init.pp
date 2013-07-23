# Class: mgmt
#
# This module manages mgmt
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# [Remember: No empty lines between comments and class definition]


class vclmgmt {
#	resources { "firewall":
#		purge => true
#	}
#	class vclmgmt::firewallpre {
#	    Firewall {
#		require => undef,
#	    }
#
#	    firewall { '000 accept all icmp':
#		proto => 'icmp',
#		action => 'accept',
#	    }->
#	    firewall { '001 accept all to lo interface':
#		proto => 'all',
#		iniface => 'lo",
#		action => 'accept',
#	    }->
#	    firewall { '002 accept related established rules':
#		proto => 'all',
#		state => ['RELATED', "ESTABLISHED'],
#		action => 'accept',
#	    }
#	}
#
#	class vclmgmt::firewallpost {
#	    firewall { '999 drop all':
#		proto => 'all',
#		action => 'drop',
#		before => undef,
#	    }
#	}
#	Firewall {
#	    before  => Class['vclmgmt::firewallpost'],
#	    require => Class['vclmgmt::firewallpre'],
#	}

    	include vclmgmt::installfrom, vclmgmt::maintenancedir, vclmgmt::mysql, vclmgmt::networks, vclmgmt::params, vclmgmt::puppetmaster, vclmgmt::services, vclmgmt::setup_security, vclmgmt::subversion, vclmgmt::yuminstall

}
