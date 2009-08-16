package YATG::Store::STDOUT;

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

__END__

Copyright (c) The University of Oxford 2007.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

