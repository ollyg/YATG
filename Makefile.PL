use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'YATG',
    VERSION_FROM      => 'usr/bin/yatg_updater', # finds $VERSION
    PREREQ_PM         => {
       'Class::Data::Inheritable'   => 0,
       'DBI'                        => 0,
       'Log::Dispatch::Syslog'      => 0,
       'Module::MultiConf'          => 0,
       'Net::Netmask'               => 0,
       'Readonly'                   => 0,
       'Regexp::Common'             => 0,
       'SNMP'                       => 0,
       'SNMP::Effective'            => '1.04',
       'Time::HiRes'                => 0,
    }, # e.g., Module::Name => 1.1

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'usr/bin/yatg_updater', # retrieve abstract from module
       AUTHOR         => 'Oliver Gorwits <oliver.gorwits@oucs.ox.ac.uk>') : ()),

    dist        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean       => { FILES => 'YATG-*' },
    realclean   => { FILES => 'Makefile.old' },
    EXE_FILES   => [ 'usr/bin/yatg_updater' ],
);
