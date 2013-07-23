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
    	include vclmgmt::installfrom, vclmgmt::maintenancedir, vclmgmt::mysql, vclmgmt::networks, vclmgmt::params, vclmgmt::puppetmaster, vclmgmt::services, vclmgmt::setup_security, vclmgmt::subversion, vclmgmt::yuminstall

}
