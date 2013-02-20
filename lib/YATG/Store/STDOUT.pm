package YATG::Store::STDOUT;

use strict;
use warnings FATAL => 'all';

use Data::Printer;

sub store {
    my ($config, $stamp, $results) = @_;

    print "YATG run at ". scalar localtime() .":\n"
        if $ENV{YATG_DEBUG} || $config->{yatg}->{debug};
    p $results;

    return 1;
}

1;
