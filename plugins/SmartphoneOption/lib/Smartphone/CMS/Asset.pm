# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Asset;

use strict;
use Smartphone::Device;

sub on_template_source_asset_upload {
    my ( $cb, $app, $rtmpl, $file ) = @_;

    # Do nothing if actual device is pc.
    my $device = Smartphone::Device->actual_device;
    return 1 if $device->is_pc;

    if (   ( lc( $app->param('filter') || '' ) eq 'class' )
        && ( lc( $app->param('filter_val') || '' ) eq 'image' ) )
    {
        $$rtmpl =~ s{(<input[^>]*type="file")}{$1 accept="image/*"}g;
    }
}

1;
