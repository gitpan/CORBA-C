use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'CORBA::C',
    'VERSION_FROM'  => 'include.pm',
    'ABSTRACT'      => 'IDL compiler to C include file',
    'PREREQ_PM'     => {
                        'CORBA::IDL::node'  => 2.21,
    },
    'PM'            => {
                        'include.pm'    => '$(INST_LIBDIR)/C/include.pm',
                        'literal.pm'    => '$(INST_LIBDIR)/C/literal.pm',
                        'name.pm'       => '$(INST_LIBDIR)/C/name.pm',
                        'type.pm'       => '$(INST_LIBDIR)/C/type.pm',
    },
    'EXE_FILES'     => ['idl2c.pl'],
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);
