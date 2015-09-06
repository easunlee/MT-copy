# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::Device;
use warnings;
use strict;

use MT;
use base qw( MT::ErrorHandler );

use MT::Util;
use Smartphone::Util;

sub PC {'pc'}

sub new {
    my $class = shift;
    my ($type_def) = @_;

    my $self = bless {}, $class;
    $self->{__props} = $type_def;
    $self;
}

sub properties     { shift->{__props} }
sub key            { shift->{__props}->{key} }
sub category       { shift->{__props}->{category} || '' }
sub os             { shift->{__props}->{os} || '' }
sub product        { shift->{__props}->{product} || '' }
sub browser        { shift->{__props}->{browser} || '' }
sub browser_engine { shift->{__props}->{browser_engine} || '' }

sub uploadable {
    my $self       = shift;
    my $uploadable = $self->{__props}->{uploadable};
    if ( $uploadable && !ref $uploadable && $uploadable !~ /\A\w*\z/ ) {
        $uploadable = MT->handler_to_coderef($uploadable);
    }
    $uploadable = $self->{__props}->{uploadable} = $uploadable->()
        if ref $uploadable eq 'CODE';
    defined($uploadable) ? $uploadable : 1;
}

sub label {
    my $self  = shift;
    my $label = $self->{__prop}->{label};
    $self->{__props}->{label} = $label->() if ref $label eq 'CODE';
    $self->{__props}->{label} || '';
}

sub registry {
    my $self      = shift;
    my $component = shift;

    $component->registry( 'device_categories', $self->category, @_ );
}

sub is_pc {
    my $self = shift;
    return $self->key eq Smartphone::Device::PC() ? 1 : 0;
}

sub switchable_to {
    my $self = shift;
    $self->{switchable_to} = shift @_ if @_;
    $self->{switchable_to};
}

sub screen_classes {
    my $self = shift;
    my ($prefix) = @_;
    $prefix = 'device-' unless defined $prefix;

    my @canditates = grep { exists $self->{__props}->{$_} }
        qw/key category os product browser browser_engine/;
    my %unique = map { lc( $self->{__props}->{$_} ) => 1 } @canditates;
    my @classes = map { $prefix . $_ } keys %unique;

    @classes;
}

sub is_supported_method {
    my $self = shift;
    my ($method) = @_;

    my $default = 0;
    if ( my $methods = $self->registry( MT->instance, 'supported_methods' ) )
    {

        $default = $methods->{_default} if defined $methods->{_default};
        return $methods->{$methods} if exists $methods->{$methods};
    }

    return $default;
}

sub pc_device {
    my $class = shift;

    # Create a pc device.
    my $device_types = $class->device_types;
    $class->new( $device_types->{ Smartphone::Device::PC() } );
}

sub request_device {
    my $class = shift;

    # Cached?
    my $cache = request_cache;
    defined( $cache->{request_device} ) && return $cache->{request_device};

    # Detect devices.
    $class->_detect_devices($cache);
    $cache->{request_device};
}

sub actual_device {
    my $class = shift;

    # Cached?
    my $cache = request_cache;
    defined( $cache->{actual_device} ) && return $cache->{actual_device};

    # Detect devices.
    $class->_detect_devices($cache);
    $cache->{actual_device};
}

sub _user_agent {
    my $class = shift;
    my ($app) = @_;
    $app ||= MT->instance;
    ( $app->can('param') ? $app->param->user_agent : undef )
        || $ENV{HTTP_USER_AGENT};
}

sub _detect_devices {
    my $class = shift;
    my ($cache) = @_;
    $cache ||= request_cache;

    my $app = MT->instance;
    my $q   = $app->param;

    # Detect from device_types by user agent.
    my $device_types = $class->device_types;
    my $ua           = $class->_user_agent($app);

    # Sort by order.
    my @ordered_device_types
        = sort { ( $a->{order} || 1000 ) <=> ( $b->{order} || 1000 ) }
        values %$device_types;

    # Check keyword.
    my $actual_device_type;
    foreach my $device_type (@ordered_device_types) {
        my $keyword = $device_type->{keyword} || next;
        if ( $ua =~ /$keyword/i ) {
            $actual_device_type = $device_type;
            last;
        }
    }

    # Not found, assumed pc, nothing to do more.
    my $pc_device = $class->pc_device;
    unless ($actual_device_type) {
        $cache->{request_device} = $cache->{actual_device} = $pc_device;
        return 1;
    }

    # Wrap as a object.
    my $actual_device = $class->new($actual_device_type);

    # Current mode must be ignored?
    if ( my $ignored_methods
        = $actual_device->registry( $app, 'ignored_methods' ) )
    {
        if ( $ignored_methods->{ $app->mode } ) {
            $cache->{actual_device}  = $actual_device;
            $cache->{request_device} = $pc_device;
            return 1;
        }
    }

    # Device switched?
    if ( my $_device = $q->param('_device') ) {
        $app->session( 'device_id', $_device );
    }

    my $request_device_type = $actual_device_type;
    my $session_device_id   = $app->session('device_id');
    if ( $session_device_id
        && ( my $session_device_type = $device_types->{$session_device_id} ) )
    {
        $request_device_type = $session_device_type;
    }

    # Wrap as a object.
    my $request_device = $class->new($request_device_type);

    # Set switchable device to request device.
    if ( $request_device->is_pc && !$actual_device->is_pc ) {
        $request_device->switchable_to($actual_device);
    }
    elsif ( !$request_device->is_pc ) {
        $request_device->switchable_to($pc_device);
    }

    $cache->{actual_device}  = $actual_device;
    $cache->{request_device} = $request_device;

    1;
}

sub load {
    my $class = shift;
    my ($id) = @_;

    # Seach repositry.
    my $device_types = $class->device_types;
    my $device_entry = $device_types->{$id};

    # Return the wrapped object or nothing.
    return $class->new($device_entry) if $device_entry;
    return;
}

sub device_types {
    my $types = MT->instance->registry('device_types') || {};

    foreach my $key ( keys %$types ) {
        $types->{$key}->{key} = $key;
        my $label = $types->{$key}->{label};
        $types->{$key}->{label} = $label->() if ref $label eq 'CODE';
    }

    $types;
}

1;
