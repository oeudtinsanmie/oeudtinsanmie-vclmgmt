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
    include xcat
    include vclmgmt::installfrom, vclmgmt::vcldirs, vclmgmt::cpan, vclmgmt::params, vclmgmt::services, vclmgmt::setup_security, vclmgmt::subversion, vclmgmt::yuminstall

	if $environment != "root" {
		include vclmgmt::mysql
	}
	
}
