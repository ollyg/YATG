package YATG::SharedStorage;
{
  $YATG::SharedStorage::VERSION = '4.112532';
}

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
