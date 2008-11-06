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

Copyright (c) The University of Oxford 2007. All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of version 2 of the GNU General Public License as published by the
Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
St, Fifth Floor, Boston, MA 02110-1301 USA

