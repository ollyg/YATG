package YATG::Callback;

use strict;
use warnings FATAL => 'all';

use Readonly;
use SNMP;

use vars qw(@EXPORT_OK);
use base 'Exporter';
@EXPORT_OK = qw(snmp_callback);

Readonly my $ifignore => qr/stack|null|channel|unrouted|eobc|netflow|loopback/i;

sub snmp_callback {
    my ($host, $error) = @_;
    my $cache   = YATG::SharedStorage->cache()   || {};
    my $results = YATG::SharedStorage->results() || {};
    my $stash   = {};

    if ($error) {
        warn "$host failed with this error: $error\n";
        return;
    }

    # rename data result keys so we can use them with aliases
    my $data = $host->data;
    foreach my $oid (keys %$data) {
        next if $oid =~ m/^\./;
        $data->{".$oid"} = delete $data->{$oid};
    }

    my $descr = $cache->{oid_for}->{ifDescr};
    my $admin = $cache->{oid_for}->{ifAdminStatus};
    if ($cache->{$host}->{build_ifindex}) {
        foreach my $iid (keys %{$data->{$descr}}) {
            next if $data->{$descr}->{$iid} =~ $ifignore;
            next if $data->{$admin}->{$iid} != 1;

            $stash->{$iid}->{is_interesting} = 1;
        }
    }

    foreach my $oid (keys %$data) {
        my $leaf  = $cache->{leaf_for}->{$oid};
        my $store = $cache->{oids}->{$leaf}->{store};
        next if !defined $store;

        # only a hint, as some INTEGERs are not enumerated types
        my $enum = SNMP::getType($leaf) eq 'INTEGER' ? 1 : 0;
        my $enum_val = undef;

        if ($cache->{oids}->{$leaf}->{indexer} eq 'iid') {
            foreach my $iid (keys %{$data->{$oid}}) {
                next unless $stash->{$iid}->{is_interesting};
                my $enum_val = SNMP::mapEnum($leaf, $data->{$oid}->{$iid})
                    if $enum;

                $results->{$store}->{$host}->{$leaf}
                    ->{$data->{$descr}->{$iid}} = ($enum and defined $enum_val)
                        ? $enum_val : $data->{$oid}->{$iid};
            }
        }
        else {
            foreach my $id (keys %{$data->{$oid}}) {
                my $enum_val = SNMP::mapEnum($leaf, $data->{$oid}->{$id})
                    if $enum;

                $results->{$store}->{$host}->{$leaf}->{$id}
                    = ($enum and defined $enum_val)
                        ? $enum_val : $data->{$oid}->{$id};
            }
        }
    }
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

