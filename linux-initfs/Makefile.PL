use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(

	# source location
    META_MERGE		=> {
    	resources	=> {
	    repository	=> 'https://github.com/kcodyjr/kcody-perl',
	},
    },

	# package distribution
    NAME		=> 'Linux::InitFS',
    LICENSE		=> 'lgpl_2_1',
    VERSION_FROM	=> 'Linux/InitFS.pm', # finds $VERSION
    ABSTRACT_FROM	=> 'Linux/InitFS.pm',
    PREREQ_PM		=> {
    	Carp		=> 0,
	Exporter	=> 0,
    },
    dist		=> {
        COMPRESS	=> 'gzip',
	SUFFIX		=> 'gz',
    },

	# send flames to...
    AUTHOR		=> 'Kevin Cody-Little <kcody@cpan.org>',

	# executable hook for kernel build
	INSTALLSCRIPT => '/usr/libexec',
	INSTALLSITESCRIPT => '/usr/libexec',
	INSTALLVENDORSCRIPT => '/usr/libexec',
	EXE_FILES => [ gen_init_cpio_spec ]

);
