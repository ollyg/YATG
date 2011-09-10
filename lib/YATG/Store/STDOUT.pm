package YATG::Store::STDOUT;
{
  $YATG::Store::STDOUT::VERSION = '4.112530';
}

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

sub store {
    my ($config, $stamp, $results) = @_;

    print "YATG run at ". scalar localtime() .":\n"
        if $ENV{YATG_DEBUG} || $config->{yatg}->{debug};
    print Dumper $results;

    return 1;
}

1;
