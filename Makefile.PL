use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::Shm::Simple',
    'ABSTRACT'	=> 'Simple data in SysV shared memory',
    'AUTHOR'	=> 'K Cody <kcody@jilcraft.com>',


    'VERSION_FROM'	=> 'Simple.pm', # finds $VERSION
    'PERL_MALLOC_OK'	=> 1,

    'LIBS'		=> [''],   # e.g., '-lm' 
    'DEFINE'		=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'		=> '',     # e.g., '-I/usr/include/other' 

    'OBJECT'		=> 'sharelite.o sharelite_shm.o Simple.o',

    'PREREQ_PM'		=> {
    	'Carp'		=> 0,
    	'Fcntl'		=> 0,
	'IPC::SysV'	=> 0,
	'DynaLoader'	=> 0,
	'UNIVERSAL'	=> 0,
	'Class::Attrib'	=> 0,
    },

    'dist'		=> {
     	COMPRESS => 'gzip',
	SUFFIX   => 'gz',
    },          

);
