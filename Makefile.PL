use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::Shm',
    'ABSTRACT'	=> 'Store variables in SysV shared memory',
    'AUTHOR'	=> 'Kevin Cody-Little <kcodyjr@gmail.com>',


    'VERSION_FROM'	=> 'IPC/Shm.pm', # finds $VERSION
    'PERL_MALLOC_OK'	=> 1,

    'LIBS'		=> [''],   # e.g., '-lm' 
    'DEFINE'		=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'		=> '',     # e.g., '-I/usr/include/other' 

    'OBJECT'		=> '',

    'PREREQ_PM'		=> {
    	'Carp'			=> 0,
	'IPC::Shm::Simple'	=> 0,
	'Storable'		=> 0,
	'UNIVERSAL'		=> 0,
	'Class::Attrib'		=> 0,
    },

    'dist'		=> {
     	COMPRESS => 'gzip',
	SUFFIX   => 'gz',
    },          

);
