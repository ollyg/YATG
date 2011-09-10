package YATG::SharedStorage;

use strict;
use warnings FATAL => 'all';

use base 'Class::Data::Inheritable';

sub factory {
    my $class = shift;
    my @accessors = @_;
    return unless scalar @accessors;

    map {$class->mk_classdata($_)} @accessors;
}

1;
