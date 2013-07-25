class vclmgmt::cpan {

    define vclmgmt::cpan::command() {
        include vclmgmt::params
	$command = "${vclmgmt::params::cpan_command} ${name}"

	exec { $command :
    	    require => Class['vclmgmt::yuminstall'],
	}
    }
        

    vclmgmt::cpan::command { $vclmgmt::params::cpan_list :

    }
}
