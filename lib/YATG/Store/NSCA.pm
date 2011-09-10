package YATG::Store::NSCA;
{
  $YATG::Store::NSCA::VERSION = '4.112530';
}

use strict;
use warnings FATAL => 'all';

use YATG::SharedStorage;
YATG::SharedStorage->factory(qw(dns_cache));

use Net::DNS;
use Regexp::Common 'net';

sub store {
    my ($config, $stamp, $results) = @_;
    my $dns_cache = YATG::SharedStorage->dns_cache;
    my $ignore_ports  = $config->{nsca}->{ignore_ports};
    my $ignore_descr  = $config->{nsca}->{ignore_descr};
    my $send_nsca_cmd = &find_command($config, 'send_nsca');
    my $send_nsca_cfg = $config->{nsca}->{config_file};
    my $service_name  = $config->{nsca}->{service_name};

    my $nsca_server = $config->{nsca}->{nsca_server}
        or die "Must specify an nsca server in configuration.\n";

    # results look like this:
    #   $results->{device}->{leaf}->{port} = {value}

    my $status = {};
    # build $status->{host}->{port}->{descr => '', state => ''}
    foreach my $device (keys %$results) {
        foreach my $leaf (keys %{$results->{$device}}) {
            foreach my $port (keys %{$results->{$device}->{$leaf}}) {

                my $host = 
                    $dns_cache->{$device} || &get_hostname_for($device) || next;
                $status->{$host}->{$port}->{$leaf} = $results->{$device}->{$leaf}->{$port};
            } # port
        } # leaf
    } # device

    # get handle in outer scope
    open my $oldout, '>&', \*STDOUT or die "Can't dup STDOUT: $!";

    # back up STDOUT then redirect it to quieten send_nsca command
    unless ($ENV{YATG_DEBUG} || $config->{yatg}->{debug}) {
        open STDOUT, '>', '/dev/null'   or die "Can't redirect STDOUT: $!";
    }

    # open connection to send_nsca
    open(my $send_nsca, '|-', $send_nsca_cmd, '-H', $nsca_server, '-c', $send_nsca_cfg, '-d', '!', '-to', 1)
        or die "can't fork send_nsca: $!";

    # build and send report for each host
    foreach my $host (keys %$status) {
        my $combined_error=q{}; # combine the error messages to fit in nagios report

        foreach my $port (keys %{$status->{$host}}) {
            next if $port =~ m/$ignore_ports/;

            my $ifOperStatus = $status->{$host}->{$port}->{ifOperStatus} || next;
            my $ifAlias      = $status->{$host}->{$port}->{ifAlias}      || '';
            next if length $ifAlias and $ifAlias =~ m/$ignore_descr/;

            if ($ifOperStatus ne 'up') {
                $combined_error .= " WARN: $port ($ifAlias) is $ifOperStatus;";
            }
        } # port

        # $ECHO "$SERVER;$SERVICE;$RESULT;$OUTPUT" | $CMD -H $DEST_HOST -c $CFG -d ";"
        if (length $combined_error) {
            print $send_nsca "$host!$service_name!2!$combined_error\n";
        }
        else {
            print $send_nsca "$host!$service_name!0! OK: all activated interfaces are running\n";
        }
    } # host

    # close connection to send_nsca (will chirp)
    close $send_nsca or die "can't close send_nsca: $!";

    # restore STDOUT
    open STDOUT, '>&', $oldout or die "Can't dup \$oldout: $!";

    return 1;
}

# get hostname for ip
sub get_hostname_for {
    my $device = shift;
    return $device if $device !~ m/^$RE{net}{IPv4}$/;

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search($device);

    my $hostname = $device; 
    if ($query) {
        foreach my $rr ($query->answer) {
            next unless $rr->type eq 'PTR';
            $hostname = $rr->ptrdname;
            last;
        }
    }
    return $hostname;
}

sub find_command {
    my ($config, $command) = @_;
    my $key = $command . '_cmd';

    return $config->{nsca}->{$key} if
        exists $config->{nsca}->{$key}
        and defined $config->{nsca}->{$key};

    use Config;
    require File::Spec;
    require ExtUtils::MakeMaker;

    if( File::Spec->file_name_is_absolute($command) ) {
        return MM->maybe_command($command);
    }
    else {
        for my $dir (
            (split /\Q$Config{path_sep}\E/, $ENV{PATH}),
            File::Spec->curdir
        ) {           
            my $abs = File::Spec->catfile($dir, $command);
            return $abs if $abs = MM->maybe_command($abs);
        }
    }

    die "Could not find command [$command] in path\n";
}

1;

# ABSTRACT: Back-end module to send polled data to a Nagios service


__END__
=pod

=head1 NAME

YATG::Store::NSCA - Back-end module to send polled data to a Nagios service

=head1 VERSION

version 4.112530

=head1 DESCRIPTION

This module checks for device ports which are administratively enabled, but
which are showing not connected to anything, at the time of polling. A Nagios
CRITICAL result will be generated for such ports.

Only one check result per device is submitted (i.e. I<not> one result per
port). If there are multiple ports in an alarm state on the same device, then
they will all be mentioned in the single service check report.

When all enabled ports are connected, an OK result is returned.

=head1 CONFIGURATION

At a minimum, you must provide details of the location of your Nagios NSCA
server, in the main configuration file:

 nsca:
     nsca_server: '192.0.2.1'

In your YATG configuration file, you must also include this store module on
the OIDs required to generate a check result:

 oids:
     "ifOperStatus":   [ifindex, nsca]
     "ifAlias":        [ifindex, nsca]

=head2 Optional Configuration

You can also supply the following settings in the main configuration file to
override builtin defaults, like so:

 nsca:
     send_nsca_cmd: '/usr/bin/send_nsca'
     config_file:   '/etc/send_nsca.cfg'
     ignore_ports:  '^(?:Vlan|Po)\d+$'
     ignore_descr:  '(?:SPAN)'
     service_name:  'Interfaces Status'

=over 4

=item C<send_nsca_cmd>

The location of the C<send_nsca> command on your system. YATG will default to
searching for C<send_nsca> in the application's current PATH.

=item C<config_file>

The location of the configuration file for the C<send_nsca> program. This
defaults to C</etc/send_nsca.cfg>.

=item C<ignore_ports>

Device port names (OID C<ifDescr>) to skip when submitting results. This
defaults to anything like a Vlan interface, or Cisco PortChannel. Supply the
content of a Perl regular expression, as in the example above.

=item C<ignore_descr>

Device port description fields matching this value cause the port to be
skipped when submitting results. This defaults to anything containing the word
"SPAN". Supply the content of a Perl regular expression, as in the example
above.

=item C<service_name>

The Nagios Service Check name to use when submitting results. This must match
the configured name on your Nagios server, and defaults to "Interfaces
Status".

=back

=head1 SEE ALSO

=over 4

=item Opsview at L<http://www.opsview.org>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

