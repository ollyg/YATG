package YATG::Store::NSCA;

use strict;
use warnings FATAL => 'all';

use YATG::SharedStorage;
YATG::SharedStorage->factory(qw( ifOperStatus ifInErrors ifInDiscards ));

# initialize cache of previous run's data
YATG::SharedStorage->ifOperStatus({});
YATG::SharedStorage->ifInErrors({});
YATG::SharedStorage->ifInDiscards({});

sub echo { main::to_log(shift) if $ENV{YATG_DEBUG} }

sub store {
    my ($config, $stamp, $results) = @_;

    my $ignore_ports = $config->{nsca}->{ignore_ports};
    my $ignore_descr = $config->{nsca}->{ignore_descr};

    my $ignore_status_descr  = $config->{nsca}->{ignore_status_descr};
    my $ignore_error_descr   = $config->{nsca}->{ignore_error_descr};
    my $ignore_discard_descr = $config->{nsca}->{ignore_discard_descr};

    my $send_nsca_cmd  = $config->{nsca}->{send_nsca_cmd};
    my $send_nsca_cfg  = $config->{nsca}->{config_file};
    my $service_prefix = $config->{nsca}->{service_prefix};

    my $ifOperStatusCache = YATG::SharedStorage->ifOperStatus();
    my $ifInErrorsCache   = YATG::SharedStorage->ifInErrors();
    my $ifInDiscardsCache = YATG::SharedStorage->ifInDiscards();

    my $cache = YATG::SharedStorage->cache();

    my $nsca_server = $config->{nsca}->{nsca_server}
        or die "Must specify an nsca server in configuration.\n";

    # results look like this:
    #   $results->{device}->{leaf}->{port} = {value}
    # build instead
    #   $status->{device}->{port}->{leaf} = {value}

    my $status = {};
    foreach my $device (keys %$results) {
        foreach my $leaf (keys %{$results->{$device}}) {
            foreach my $port (keys %{$results->{$device}->{$leaf}}) {
                $status->{$device}->{$port}->{$leaf}
                    = $results->{$device}->{$leaf}->{$port};
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
    foreach my $device (keys %$status) {
        my $status_report   = q{}; # combine the error messages to fit in nagios report
        my $errors_report   = q{}; # combine the error messages to fit in nagios report
        my $discards_report = q{}; # combine the error messages to fit in nagios report

        my @ports_list = exists $cache->{'interfaces_for'}->{$device}
          ? keys %{ $cache->{'interfaces_for'}->{$device} }
          : keys %{ $status->{$device} };

        foreach my $port (@ports_list) {
            next if $port =~ m/$ignore_ports/;

            my $ifOperStatus = $status->{$device}->{$port}->{ifOperStatus};
            my $ifInErrors   = $status->{$device}->{$port}->{ifInErrors};
            my $ifInDiscards = $status->{$device}->{$port}->{ifInDiscards};

            next unless ($ifOperStatus or $ifInErrors or $ifInDiscards);

            my $ifAlias = $status->{$device}->{$port}->{ifAlias} || '';
            next if length $ifAlias and $ifAlias =~ m/$ignore_descr/;

            my $skip_oper = (length $ifAlias and $ignore_status_descr
              and $ifAlias =~ m/$ignore_status_descr/) ? 1 : 0;
            my $skip_err  = (length $ifAlias and $ignore_error_descr
              and $ifAlias =~ m/$ignore_error_descr/) ? 1 : 0;
            my $skip_disc = (length $ifAlias and $ignore_discard_descr
              and $ifAlias =~ m/$ignore_discard_descr/) ? 1 : 0;

            if ($ifOperStatus) {
                if (not $skip_oper and $ifOperStatus ne 'up') {
                    $status_report ||= 'NOT OK - DOWN: ';
                    $status_report .= "$port($ifAlias) ";
                }

                # update cache
                $ifOperStatusCache->{$device}->{$port} = $ifOperStatus;

                if ($ifOperStatus ne 'up') {
                    # can skip rest of this port's checks and reports
                    $ifInErrorsCache->{$device}->{$port} = $ifInErrors
                      if $ifInErrors;
                    $ifInDiscardsCache->{$device}->{$port} = $ifInDiscards
                      if $ifInDiscards;
                    next;
                }
            }

            if ($ifInErrors) {
                # compare cache
                if (not $skip_err
                    and exists $ifInErrorsCache->{$device}->{$port}
                    and $ifInErrors > $ifInErrorsCache->{$device}->{$port}) {
                    $errors_report ||= 'NOT OK - Errors: ';
                    $errors_report .= "$port($ifAlias) ";
                }

                # update cache
                $ifInErrorsCache->{$device}->{$port} = $ifInErrors;
            }

            if ($ifInDiscards) {
                # compare cache
                if (not $skip_disc
                    and exists $ifInDiscardsCache->{$device}->{$port}
                    and $ifInDiscards > $ifInDiscardsCache->{$device}->{$port}) {
                    $discards_report ||= 'NOT OK - Discards: ';
                    $discards_report .= "$port($ifAlias) ";
                }

                # update cache
                $ifInDiscardsCache->{$device}->{$port} = $ifInDiscards;
            }
        } # port

        my $host = exists $cache->{host_for} ? $cache->{host_for}->{$device}
                                             : $device;

        # $ECHO "$SERVER;$SERVICE;$RESULT;$OUTPUT" | $CMD -H $DEST_HOST -c $CFG -d ";"

        if (exists $results->{$device}->{ifOperStatus}) {
            if (length $status_report) {
                my $output = "$host!$service_prefix Status!2!$status_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Status!0!OK: all activated interfaces are running\n";
                echo $output;
                print $send_nsca $output;
            }
        }

        if (exists $results->{$device}->{ifInErrors}) {
            if (length $errors_report) {
                my $output = "$host!$service_prefix Errors!2!$errors_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Errors!0!OK: No errors.\n";
                echo $output;
                print $send_nsca $output;
            }
        }

        if (exists $results->{$device}->{ifInDiscards}) {
            if (length $discards_report) {
                my $output = "$host!$service_prefix Discards!2!$discards_report\n";
                echo $output;
                print $send_nsca $output;
            }
            else {
                my $output = "$host!$service_prefix Discards!0!OK: No discards.\n";
                echo $output;
                print $send_nsca $output;
            }
        }
    } # host

    # close connection to send_nsca (will chirp)
    close $send_nsca or die "can't close send_nsca: $!";

    # restore STDOUT
    open STDOUT, '>&', $oldout or die "Can't dup \$oldout: $!";

    return 1;
}

1;

# ABSTRACT: Back-end module to send polled data to a Nagios service

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
     service_prefix:  'Interfaces'

=over 4

=item C<send_nsca_cmd>

The location of the C<send_nsca> command on your system. YATG will default to
C</usr/bin/send_nsca> and if you supply a value it must be a fully qualified
path.

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

=item C<service_prefix>

Prefix of he Nagios Service Check name to use when submitting results. To this
is added the name of the data check such as "Status" or "Errors".  This must
match the configured name on your Nagios server, and defaults to "Interfaces".

=back

=head1 SEE ALSO

=over 4

=item Nagios NSCA at L<http://docs.icinga.org/latest/en/nsca.html>

=back
