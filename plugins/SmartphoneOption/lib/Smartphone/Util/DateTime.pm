# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::Util::DateTime;

use strict;

use base 'Exporter';

our @EXPORT = qw(
    split_template_date_param
    split_template_time_param
    join_datetime_request_param
);

# TODO: Only for Japan format. Impliment for locales.

sub join_datetime_request_param {
    my ($app) = @_;
    $app ||= MT->instance;
    return unless $app->can('param');
    my $q = $app->param;

    # Do nothing unless beacon.
    return unless $q->param('datetime_splited_beacon');

    # Parse params.
    my %datetimes;
    my %params = $app->param_hash;
    while ( my ( $name, $value ) = each %params ) {
        next unless $name =~ /^(.+?)_(year|month|day|hour|minute|second)$/;
        my ( $prefix, $part ) = ( $1, $2 );
        $datetimes{$prefix} ||= {};
        $datetimes{$prefix}->{$part} = $value;
    }

    # Join and back as date and time.
    while ( my ( $prefix, $parts ) = each %datetimes ) {

        # Date.
        $q->param( $prefix,
            join( '-', $parts->{year}, $parts->{month}, $parts->{day} ) )
            if $parts->{year} && $parts->{month} && $parts->{day};

        # Time.
        $q->param( $prefix,
            join( ':', $parts->{hour}, $parts->{minute}, $parts->{second} ) )
            if $parts->{hour} && $parts->{minute} && $parts->{second};
    }
}

1;
