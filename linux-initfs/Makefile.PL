use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    META_MERGE		=> {
    	resources	=> {
	    repository	=> 'https://github.com/kcodyjr/kcody-perl',
	},
    },
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
    AUTHOR		=> 'Kevin Cody-Little <kcody@cpan.org>',
);
