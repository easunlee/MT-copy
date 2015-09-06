# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Dashboard;

use strict;
use Smartphone::Util;
use Smartphone::Device;

sub on_template_param_dashboard {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # CSS to display blog_stats tabs in white list.
    my @css;
    my $blog_stats_tabs_white_list
        = $device->registry( $app, 'blog_stats_tabs_white_list' )
        || { entry => 1 };
    while ( my ( $tab, $show ) = each %$blog_stats_tabs_white_list ) {
        next unless $show;
        push @css, <<"CSS";
            #dashboard #blog_stats #blog-stats-widget-tabs li#$tab-tab { display: inline-block; }
            #dashboard #blog_stats #$tab-panel { display: block; }
CSS
    }

    $param->{html_head} ||= '';
    $param->{html_head}
        .= q{<style type="text/css">} . join( "\n", @css ) . q{</style>};

    1;
}

sub on_template_param_widget {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

# Never show original link to create blog and link to list screens on system scope.
    $param->{$_} = 0
        for
        qw/can_create_new_entry can_create_new_page can_create_blog can_list_entries can_list_pages can_list_comments/;

    # Permissions for smartphone shortcut.
    my $user = $app->user;
    foreach my $loop_name (qw/website_object_loop blog_object_loop/) {
        my $loop = $param->{$loop_name} || next;
        foreach my $loop_param (@$loop) {
            $loop_param->{shortcut_loop}
                = _dashboard_blog_shortcut( $app, $device, $loop_param );

            # Unset params not to be shown.
            $loop_param->{"can_$_"} = 0
                for
                qw/create_new_entry create_new_page access_to_template_list access_to_blog_list access_to_blog_config_screen apply_theme use_tools_search/;
        }
    }

    1;
}

sub _dashboard_blog_shortcut {
    my ( $app, $device, $param ) = @_;

    my $blog_id = $param->{blog_id} || $param->{website_id} || 0;
    my $scope = $param->{blog_id} ? 'blog' : 'website';
    my $perms = $app->user->permissions($blog_id);

    # Enum shortcut.
    my $shortcut = $device->registry( $app, 'dashboard_blog_shortcut' )
        || return [];
    my @shortcut;
    foreach my $values ( values %$shortcut ) {
        if ( defined $values->{scope} ) {
            next if $scope ne $values->{scope};
        }

        my %sc = %$values;

        # Check permission.
        if ( my $permit_action = $sc{permit_action} ) {
            next
                if !$param->{ 'can_' . $permit_action }
                    && !$perms->can_do($permit_action);
        }

        # Generate link href.
        if ( my $blog_scope = $sc{blog_scope} ) {
            my %args = %$blog_scope;
            $args{blog_id} = $blog_id;
            $sc{href} = $app->uri( args => \%args );
        }

        push @shortcut, \%sc if $sc{href};
    }

    # Sort by order.
    my @ordered = sort { ( $a->{order} || 1000 ) <=> ( $b->{order} || 1000 ) }
        @shortcut;

    \@ordered;
}

sub on_template_param_blogs_widget {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Common widget transformer.
    on_template_param_widget(@_);

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # Insert blog/website shortcut template.
    my $shortcut_node
        = $tmpl->createElement( 'loop', { name => 'shortcut_loop', } );

    $shortcut_node->innerHTML(
        q{
        <li><a class="shortcut button" href="<mt:var name='href'>"><mt:var name="label" escape="html"></a></li>
    }
    );

    my @target_nodes = grep {
        my $name = $_->getAttribute('name');
        $name eq 'can_create_new_page' || $name eq 'can_create_new_entry';
    } @{ $tmpl->getElementsByTagName('if') };

    $tmpl->insertBefore( $shortcut_node, $_ ) for @target_nodes;

    1;
}

1;
