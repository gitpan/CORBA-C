use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::C',
    'VERSION_FROM'  => 'include.pm',
    'ABSTRACT'      => 'C include genrerator from IDL file',
    'PREREQ_PM'     => {
                        'CORBA::IDL::node'  => 0,
    },
    'PM'            => {
                        'include.pm'    => '$(INST_LIBDIR)/C/include.pm',
                        'literal.pm'    => '$(INST_LIBDIR)/C/literal.pm',
                        'name.pm'       => '$(INST_LIBDIR)/C/name.pm',
    },
    'EXE_FILES'     => ['idl2c'],
    'AUTHOR'        => "Francois PERRAD (perrad\@besancon.sema.slb.com)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
