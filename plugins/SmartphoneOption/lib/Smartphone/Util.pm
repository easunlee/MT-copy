# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::Util;

use strict;

use MT::Util;
use Smartphone::Device;

use base 'Exporter';

our @EXPORT = qw(
    plugin
    request_cache
    request_registry
    merge_device_registry
    plugin_static_url
    unescape_yaml_comment
);

sub plugin {
    MT->component('smartphoneoption');
}

sub request_cache {
    my $cache = MT::Request->instance->cache('smartphone');
    MT::Request->instance->cache( 'smartphone', $cache = {} ) unless $cache;

    $cache;
}

sub request_registry {
    my $cache = request_cache;

    my $entries = ( $cache->{registry} ||= {} );

    # Check the last param.
    # Return entire if no params.
    my $last_param = pop @_ || return $entries;

    if ( ref $last_param eq 'HASH' ) {

        # Setter.
        # If no keys, do nothing.
        my $last_key = pop @_ || return;

        # Traverse and digg keys.
        $entries = ( $entries->{$_} ||= {} ) for @_;

        $entries->{$last_key} = $last_param;
        return $last_param;
    }
    else {

        # Getter.
        push @_, $last_param;

        # Traverse until key exists.
        foreach (@_) {
            $entries = $entries->{$_};
            return unless $entries;
        }

        return $entries;
    }
}

sub merge_device_registry {
    my ( $pathes, $callback, $defaults ) = @_;
    $defaults ||= {};
    my $app = MT->instance;

    # Normalize.
    $pathes = [$pathes] if ref $pathes ne 'ARRAY';

    # Caches?
    my $entries = request_registry(@$pathes);
    return $entries if defined $entries;

    # Initialize.
    request_registry( @$pathes, $entries = $defaults );

    # Request device.
    my $device = Smartphone::Device->request_device || return $entries;
    return $entries if $device->is_pc;

    # Run callback.
    $callback->( $app, $device, $entries );
    $entries;
}

sub plugin_static_url {
    my ( $plugin, $path, $options ) = @_;
    $plugin ||= plugin;

    my $url = MT::Util::caturl( MT->static_path, $plugin->envelope, $path );
    my $version;
    $version = $plugin->{version} if !defined( $options->{version} );
    $url .= '?v=' . $plugin->{version} if $version;

    $url;
}

sub static_url_of {
    my ($path) = @_;

    # Build static file url with plugin version.
    MT::Util::caturl( MT->static_path, plugin->envelope, $path ) . '?v='
        . plugin->{version};
}

sub unescape_yaml_comment {
    my ($value) = @_;

    $value =~ s!\\#!#!g if $value;
    $value;
}

1;
