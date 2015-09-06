# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::Device::iOS;
use warnings;
use strict;

use Smartphone::Device;

sub uploadable {
    my $ua = Smartphone::Device->_user_agent;
    my ($major_version) = ( $ua =~ m/OS (\d+)/ );
    !( $major_version && $major_version <= 5 );
}

1;
