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


__END__

Copyright (c) The University of Oxford 2007.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

