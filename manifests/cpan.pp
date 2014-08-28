class vclmgmt::cpan {

	exec { "/usr/bin/cpanp -i --skiptest ${name}" :
	
	}
}
