use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::Shm::Simple',
    'VERSION_FROM' => 'Simple.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    'OBJECT'    => 'sharelite_shm.o Simple.o',
    'dist'      => {
        COMPRESS => 'gzip', SUFFIX => 'gz',
    },          
);
