# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Search;

use strict;
use Smartphone::Util;

sub on_template_param_search_replace {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q    = $app->param;
    my $type = $q->param('_type');

    # Request device.
    my $device = Smartphone::Device->request_device || return;
    return 1 if $device->is_pc;

    # Filter tabs(currently tabs is hidden by CSS).
    if ( my $search_apis_white_list
        = $device->registry( $app, 'search_apis_white_list' ) )
    {
        $param->{search_tabs}
            = [ grep { $search_apis_white_list->{ $_->{key} } }
                @{ $param->{search_tabs} } ];
    }

    if ( my $search_replace_prefs
        = $device->registry( $app, 'search_replace_prefs' ) )
    {

        # Set callback results_template to insert button.
        if ( $param->{results_template} =~ /([a-z0-9\-_]+)\.tmpl/i ) {
            my $tmpl_name = $1;
            $app->add_callback(
                'template_param.' . $tmpl_name,
                5, plugin,
                sub {
                    my ( $cb, $app, $inner_param, $tmpl ) = @_;

                  # Insert select all button(currently actions hidden by CSS).
                    if ( $search_replace_prefs->{add_select_all_button} ) {
                        my @action_buttons_nodes = grep {
                            $_->getAttribute('name') eq 'action_buttons'
                        } @{ $tmpl->getElementsByTagName('setvarblock') };

                        if (@action_buttons_nodes) {
                            require Smartphone::CMS::Listing;
                            Smartphone::CMS::Listing::_insert_select_all_button(
                                $tmpl, 'action_buttons',
                                $action_buttons_nodes[0],
                                'insertAfter' );
                        }
                    }

                    # Run at once.
                    $app->remove_callback($cb);
                }
            );
        }

        # Change page name.
        if ( $search_replace_prefs->{title_by_type} ) {
            my @header_nodes
                = grep { $_->getAttribute('name') =~ m!include/header!; }
                @{ $tmpl->getElementsByTagName('include') };
            if (@header_nodes) {
                my $page_title_node = $tmpl->createElement(
                    'setvar',
                    {   name  => 'page_title',
                        value => plugin->translate(
                            'Search [_1]', $param->{search_label}
                        ),
                    }
                );
                $tmpl->insertBefore( $page_title_node, $header_nodes[0] );
            }
        }

        # Other params.
        my $can_replace = $search_replace_prefs->{can_replace};
        $param->{can_replace} = $can_replace if defined $can_replace;

        my $can_search_by_date = $search_replace_prefs->{can_search_by_date};
        $param->{can_search_by_date} = $can_search_by_date
            if defined $can_search_by_date;

        if ( $search_replace_prefs->{disable_list_actions} ) {
            delete $param->{$_}
                for
                qw/list_actions has_list_actions use_actions has_pulldown_actions/;
        }

        $param->{screen_class} .= ' listing-device-' . $device->category;

        $param->{jq_js_include} .= q{
            jQuery('table.listing-table').find('.title, .comment').mtEllipsisText();
            jQuery('table.listing-table tbody').selectable({
                filter: 'tr',
                cancel: 'tr.no-action, a, .select-all, .text, .can-select, button, pre, :input:not([name=id])',
                anchorsTarget: '.col a',
            });
        } if $search_replace_prefs->{ellipsis_text};
    }
}

1;
