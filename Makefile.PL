use inc::Module::Install 0.67;
perl_version '5.008001';
  
name        'YATG';
all_from    'script/yatg_updater';

install_script  'yatg_updater';

requires    'Class::Data::Inheritable' => 0;
requires    'DBI' => 0;
requires    'Log::Dispatch::Syslog' => 0;
requires    'Module::MultiConf' => 0;
requires    'Net::Netmask' => 0;
requires    'Readonly' => 0;
requires    'Regexp::Common' => 0;
requires    'SNMP' => 0;
requires    'SNMP::Effective' => 1.04;
requires    'Time::HiRes' => 0;

recommends  'Cache::Memcached' => 0;
recommends  'RPC::Serialized::Handler' => 0;
recommends  'Tie::File::FixedRecLen::Store' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::Pod' => 0;
test_requires  'Test::Pod::Coverage' => 0;

WriteAll;

