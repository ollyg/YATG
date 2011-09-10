
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Fast SNMP data poller daemon, with storage and graphing",
  "AUTHOR" => "Oliver Gorwits <oliver\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "YATG",
  "EXE_FILES" => [
    "bin/yatg_updater"
  ],
  "LICENSE" => "perl",
  "NAME" => "YATG",
  "PREREQ_PM" => {
    "Cache::Memcached" => 0,
    "Class::Data::Inheritable" => 0,
    "Config" => 0,
    "DBI" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "Fcntl" => 0,
    "File::Basename" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "FindBin" => 0,
    "Log::Dispatch::Syslog" => 0,
    "Module::MultiConf" => "0.0301",
    "Net::DNS" => 0,
    "Net::Netmask" => 0,
    "POSIX" => 0,
    "RPC::Serialized::Client::INET" => 0,
    "RPC::Serialized::Handler" => 0,
    "Readonly" => 0,
    "Regexp::Common" => 0,
    "SNMP" => 0,
    "SNMP::Effective" => 0,
    "Symbol" => 0,
    "Tie::File::FixedRecLen" => 0,
    "Tie::File::FixedRecLen::Store" => 0,
    "Time::HiRes" => 0,
    "Time::Local" => 0,
    "base" => 0,
    "integer" => 0,
    "strict" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.112530",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



