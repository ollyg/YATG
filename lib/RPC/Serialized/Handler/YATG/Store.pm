package RPC::Serialized::Handler::YATG::Store;

use strict;
use warnings FATAL => 'all';

use base 'RPC::Serialized::Handler';
use YATG::Store::Disk;

sub invoke {
    my $self = shift;
    return YATG::Store::Disk::store(@_);
}

1;

# ABSTRACT: RPC handler for YATG::Store::Disk

=head1 DESCRIPTION

This module implements an L<RPC::Serialized> handler for L<YATG::Store::Disk>.
There is no special configuration, and all received parameters are passed on
to C<YATG::Store::Disk::store()> verbatim.

=head1 INSTALLATION

You'll need to run an RPC::Serialized server, of course, and configure it to
serve this handler. There are files in the C<examples/> folder of this
distribution to help with that, e.g. C<rpc-serialized.server.yml>:

 ---
 # configuration for rpc-serialized server with YATG handlers
 rpc_serialized:
     handlers:
         yatg_store:    "RPC::Serialized::Handler::YATG::Store"
         yatg_retrieve: "RPC::Serialized::Handler::YATG::Retrieve"
 net_server:
     port: 1558
     user: daemon
     group: daemon


You should head over to the RPC::Serialized documentation to learn how to set
that up. We use a pre-forking L<Net::Server> based implementation to receive
port traffic data and store to disk, then serve it back out to CGI on a web
server.

=head1 SEE ALSO

=over 4

=item L<RPC::Serialized>

=back
