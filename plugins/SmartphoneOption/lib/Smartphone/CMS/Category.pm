# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Category;

use strict;
use Smartphone::Device;

sub on_template_param_list {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q     = $app->param;
    my $id    = $param->{id};
    my $class = $param->{class} || 'category';

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # Insert additional jQuery Includes.
    my @footer_nodes = grep { $_->getAttribute('name') =~ /footer\.tmpl/; }
        @{ $tmpl->getElementsByTagName('include') };
    my $jq_js_include_node = $tmpl->createElement(
        'setvarblock',
        {   name   => 'jq_js_include',
            append => 1,
        }
    );

    $jq_js_include_node->innerHTML(
        q{
        // Unable normal hover action and make highlitable.
        setHoverAction = function($element) {
            var url = $element.find('.item-label a').attr('href');
            if ( url ) {
                $element.mtTouchHighlight({ toggleClass: 'selected' });
            }
            return false;
        };
    }
    );

    $tmpl->insertBefore( $jq_js_include_node, $footer_nodes[0] );

}

1;
