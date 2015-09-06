# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Listing;

use strict;
use Smartphone::Util;
use Smartphone::Device;

our %actions_vars = (
    buttons   => 'button_actions',
    list      => 'list_actions',
    more_list => 'more_list_actions',
);

sub load_list_properties {

    # Gather from device registry.
    my $app = MT->instance;
    my $device_categories = $app->registry('device_categories') || return {};

    my %list_properties;
    foreach my $category ( keys %$device_categories ) {
        my $models = $app->registry( 'device_categories', $category,
            'list_properties' );

        # Auto conditon: filter by current device.
        my $auto_condition = sub {
            my $prop = shift;
            my $device = Smartphone::Device->request_device || return;
            $device->category eq $category ? 1 : 0;
        };

        foreach my $model ( keys %$models ) {
            $list_properties{$model} ||= {};
            my $registry = $app->registry( 'device_categories', $category,
                'list_properties', $model );

            # Set auto condition and add to registry.
            while ( my ( $id, $prop ) = each %$registry ) {
                $prop->{condition} ||= $auto_condition;
                $list_properties{$model}->{$id} = $prop;
            }
        }
    }

    \%list_properties;
}

sub _filter_list_actions {
    my ( $list_actions_filter, $param, $gather ) = @_;

    my @actions_order = qw/buttons list more_list/;
    my @all_actions = @{ $param->{all_actions} || [] };

    # Filtering.
    if ($list_actions_filter) {
        @all_actions = ();
        foreach my $var ( values %actions_vars ) {
            if ( $param->{$var} && ref $param->{$var} eq 'ARRAY' ) {
                my @actions = grep {

                    # Filtering by registry.
                    my $show = 0;
                    if ( my $key = $_->{key} ) {

                        # Change label and set new order.
                        if ( my $filter = $list_actions_filter->{$key} ) {
                            $show = 1;
                            if ( ref $filter eq 'HASH' ) {
                                if ( my $label
                                    = $list_actions_filter->{$key}->{label} )
                                {
                                    $_->{label}
                                        = ref $label eq 'CODE'
                                        ? $label->()
                                        : $label;
                                }
                                $_->{order} = $filter->{order}
                                    if $filter->{order};
                            }
                        }
                    }

                    $show;
                } @{ $param->{$var} };

                $param->{$var} = \@actions;
                push @all_actions, @actions;
            }
        }
    }

    # Gather actions to buttons or pulldown?
    if ($gather) {
        @all_actions = ();
        my @actions;
        foreach my $pos (@actions_order) {
            my $var = $actions_vars{$pos} || next;
            push @actions, @{ $param->{$var} };
            delete $param->{$var};
        }
        my $var = $actions_vars{$gather};
        $param->{$var} = \@actions;
        push @all_actions, @actions;
    }

    # Sort each actions and reset flag params.
    $param->{all_actions} = \@all_actions;
    foreach my $var ( values %actions_vars ) {
        if ( $param->{$var} ) {
            my @actions
                = sort { ( $a->{order} || 1000 ) <=> ( $b->{order} || 1000 ) }
                @{ $param->{$var} };

            if (@actions) {
                $param->{$var} = \@actions;
            }
            else {
                delete $param->{$var};
            }
        }
    }

    $param->{$_} = @all_actions ? 1 : 0 for qw/has_list_actions use_actions/;
    $param->{$_} = $param->{list_actions}
        || $param->{more_list_actions} ? 1 : 0
        for qw/has_pulldown_actions/;
}

sub _insert_select_all_button {
    my ( $tmpl, $insert_button_var, $insert_button_node, $method ) = @_;
    $method ||= 'insertBefore';

    # Insert select all button.
    if ($insert_button_node) {
        my $select_all_node = $tmpl->createElement(
            'setvarblock',
            {   name    => $insert_button_var,
                prepend => 1,
            }
        );
        $select_all_node->innerHTML(
            q{
            <__trans_section component="smartphoneoption">
            <label for="cb-select-all" id="cb-select-all-label" class="button">
                <input type="checkbox" id="cb-select-all" name="smartphone_select_all" value="1" />
                <__trans phrase="All">
            </inner></label>
            </__trans_section>
        }
        );

        $tmpl->$method( $select_all_node, $insert_button_node );
    }
}

sub on_template_param_list_common {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q    = $app->param;
    my $type = $q->param('_type');

    # Run only once.
    return 1 if request_cache->{list_common_handled};

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    my $screen_settings = $app->registry( 'listing_screens', $type ) || {};
    my $actions_gather_as;
    if ( my $transform
        = $device->registry( $app, 'listing_screens_transform', $type ) )
    {

        # Columns fixed?
        if ( my $fixed_columns = $transform->{fixed_columns} ) {

            # Add default_sort_key to fixed columns if not defined.
            if ( my $sort_key = $screen_settings->{default_sort_key} ) {
                $fixed_columns->{$sort_key} = 0
                    unless defined( $fixed_columns->{$sort_key} );
            }

            # Filter list_columns by fixed_columns.
            $param->{list_columns} = [
                map {
                    $_->{display} = $fixed_columns->{ $_->{type} };
                    $_;
                    } grep { defined( $fixed_columns->{ $_->{type} } ); }
                    @{ $param->{list_columns} }
            ];
        }

        # Put per-page pulldown on listing footer?
        my @list_actions_nodes
            = grep { $_->getAttribute('name') eq 'list_actions' }
            @{ $tmpl->getElementsByTagName('setvarblock') };

        if ( my $per_page_on_footer = $transform->{per_page_on_footer} ) {
            my $per_page_node = $tmpl->createElement(
                'setvarblock',
                {   name   => 'list_actions',
                    append => 1,
                }
            );
            $per_page_node->innerHTML(
                q{
                <div class="per-page-option"><__trans phrase="_DISPLAY_OPTIONS_SHOW">: </div>
            }
            );

            $tmpl->insertAfter( $per_page_node, $list_actions_nodes[0] );
        }

        # Add select all button?
        if ( my $add_select_all_button = $transform->{add_select_all_button} )
        {
            _insert_select_all_button( $tmpl, 'button_actions',
                $list_actions_nodes[0], 'insertBefore' )
                if @list_actions_nodes;

        }

        # Gather actions?
        $actions_gather_as = $transform->{actions_gather_as};
    }

    # Filter list actions.
    my $list_actions_filter
        = $device->registry( $app, 'list_actions_white_list', $type );
    _filter_list_actions( $list_actions_filter, $param, $actions_gather_as );

    # Make a table selectable even if not have list_actions.
    if ( !$param->{has_list_actions} ) {
        my @list_actions_nodes
            = grep { $_->getAttribute('name') eq 'list_actions' }
            @{ $tmpl->getElementsByTagName('setvarblock') };

        my $selectable_js_node = $tmpl->createElement(
            'setvarblock',
            {   name   => 'jq_js_include',
                append => 1,
            }
        );
        $selectable_js_node->innerHTML(
            q{
            <mt:unless name="has_list_actions">
                jQuery('table.listing-table tbody').selectable({
                    filter: 'tr',
                    cancel: 'tr.no-action, a, .select-all, .text, .can-select, button, pre, :input:not([name=id])'
                });
            </mt:unless>
        }
        );
        $tmpl->insertAfter( $selectable_js_node, $list_actions_nodes[0] );
    }

    # Hide new_filter.
    $param->{html_head} .= q(
        <style type="text/css">
            <__trans_section component="smartphoneoption">
            #dialog_filter #user-filters li:last-child:before {
                content: "<__trans phrase='Filters which you created from PC.' params=')
        . $device->label . q('>"
            }
            </__trans_section>
        </style>
    );

    # Mark as a smartphone screen class.
    $param->{screen_class} ||= '';
    $param->{screen_class} .= ' listing-device-smartphone';
    $param->{screen_class} .= ' listing-has-cb' if $param->{has_list_actions};

    request_cache->{list_common_handled} = 1;
}

1;
