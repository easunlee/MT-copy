# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::CMS::Entry;

use strict;
use Smartphone::Device;
use Smartphone::Util;
use Smartphone::Util::DateTime;

sub on_template_param_edit_entry {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $q = $app->param;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    if ( my $fields = $device->registry( $app, 'edit_entry_fields' ) ) {

        # As a status message?
        my @statusmsg_fields;
        foreach my $key ( keys %$fields ) {
            if ( $fields->{$key}->{as_statusmsg} ) {
                push @statusmsg_fields, $fields->{$key}
                    if $fields->{$key}->{display};
                delete $fields->{$key};
            }
        }

        if (@statusmsg_fields) {
            my $setvarblock_node = $tmpl->createElement(
                'setvarblock',
                {   name   => 'system_msg',
                    append => 1,
                }
            );

            my $inner_html = '';
            foreach my $field ( sort { $a->{order} <=> $b->{order} }
                @statusmsg_fields )
            {
                $inner_html .= $field->{template} || '';
            }

            $setvarblock_node->innerHTML($inner_html);
            if ( my $header_node = $tmpl->getElementById('header_include') ) {
                $tmpl->insertBefore( $setvarblock_node, $header_node );
            }
        }

        # Field visibility control.
        my @fields;

        # Push _default at first.
        push @fields, $fields->{_default} if $fields->{_default};

        # Customfields.
        if ( my $customfields = $fields->{_customfields} ) {
            foreach my $looped_field ( @{ $param->{field_loop} } ) {
                next if ref $looped_field ne 'HASH';

                my $field_id = $looped_field->{field_id};
                if ( $field_id =~ /^customfield_/ ) {
                    my %field = %$customfields;
                    $field{field_id} = $field_id;
                    $field{selector} = "#sortable #${field_id}-field";
                    push @fields, \%field;
                }
            }
        }

        # Push others not started with _.
        push @fields, map {
            $fields->{$_}->{field_id} = $_;
            $fields->{$_};
        } grep { substr( $_, 0, 1 ) ne '_' } keys %$fields;

        # Join css and jquery.
        my $css = '';
        my $jq  = '';
        foreach my $field (@fields) {

            # If has selector and display.
            my $selector = unescape_yaml_comment( $field->{selector} );
            $selector = '#' . $field->{field_id} . '-field'
                if !$selector && $field->{field_id};
            my $display = $field->{display};

            $css
                .= $selector
                . " { display:"
                . ( $display ? 'block' : 'none' ) . "; }\n"
                if $selector && defined($display);

            # Raw CSS.
            $css .= unescape_yaml_comment( $field->{css} ) if $field->{css};

            # Raw jquery.
            $jq .= $field->{jquery} if $field->{jquery};
        }

        $jq .= q{
            // Disable jquery.ui sortable by replacing blank plugin.
            jQuery('.sort-enabled').removeClass('sort-enabled');
        };

        $param->{js_include} ||= '';
        $param->{js_include} .= qq{
            <style type="text/css">
                $css
            </style>
        } if $css;

        $param->{jq_js_include} .= $jq if $jq;

        # Insert text filter slot.
        if ( $fields->{convert_breaks}->{as_field} ) {
            my $convert_breaks_node = $tmpl->createElement(
                'app:setting',
                {   id    => 'convert_breaks',
                    label => plugin->translate('Format'),
                }
            );
            my $text_node = $tmpl->getElementById('text');
            $tmpl->insertAfter( $convert_breaks_node, $text_node );
        }

        # Unable richtext.
        foreach my $text_filter ( @{ $param->{text_filters} } ) {
            my $filter_key = $text_filter->{filter_key} || next;
            if ( $filter_key eq 'richtext' ) {
                $text_filter->{filter_label}
                    = plugin->translate('Rich Text(HTML mode)');
                $text_filter->{filter_key} = '_richtext';
            }
        }

        # Disable all richtext editor in MT5.2 or later.
        delete $param->{editors};
    }

    1;
}

sub on_template_param_preview_strip {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Do nothing if actual device is pc.
    my $device = Smartphone::Device->actual_device;
    return 1 if $device->is_pc;

    # Preview callback.
    if ( my $prefs = $device->registry( $app, 'prefs' ) ) {
        if ( my $preview_callback = $prefs->{preview_callback} ) {
            $preview_callback = MT->handler_to_coderef($preview_callback)
                unless ref $preview_callback eq 'CODE';

            $preview_callback->(@_) if ref $preview_callback eq 'CODE';
        }
    }
}

sub on_template_source_archetype_editor {
    my ( $cb, $app, $rtmpl, $file ) = @_;

    # Do nothing if actual device is pc.
    my $device = Smartphone::Device->actual_device;
    return 1 if $device->is_pc;

    my $ts = time();
    $$rtmpl
        =~ s!html/editor-content.html\?cs=!plugins/SmartphoneOption/editor/smartphone/html/editor-content.html?ts=$ts&cs=!i;

    $$rtmpl
        =~ s{(command-insert-file.*</a>)}{$1<mt:if name="formatted_texts"><a href="<mt:var name="script_url">?__mode=smartphoneoption_dialog_select_formatted_text&amp;_type=<mt:var name="object_type" />&amp;edit_field=<mt:var name="toolbar_edit_field">&amp;blog_id=<mt:var name="blog_id">" title="<__trans phrase="Insert Boilerplate" escape="html">" class="command-insert-formatted-text toolbar button mt-open-dialog"><span class="button-label"><__trans phrase="Insert Boilerplate"></span></a></mt:if>};

    1;
}

sub on_smartphone_template_param_preview_strip {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Arrange preview screen for smartphone.

    # Do nothing if actual device is pc.
    my $device = Smartphone::Device->actual_device;
    return 1 if $device->is_pc;

    # Custom CSS.
    $param->{js_include} ||= '';
    $param->{js_include} .= <<'HTML';
        <meta name="viewport" content="width=980;target-densitydpi=high-dpi" />
        <style type="text/css">
            .preview-screen {
                -webkit-text-size-adjust:none;
                overflow: visible;
            }
            #brand { display: none !important; }
            p.preview-label {
                font-size: 36px;
                text-align: left;
            }
            .actions-bar .button.action {
                font-size: 36px;
                line-height: 36px;
                margin-top: 16px;
                margin-bottom: 16px;
            }

            @media only screen and (min-device-width: 481px) and (max-device-width: 1024px) {
                p.preview-label {
                    font-size: 18px;
                }
                .actions-bar .button.action {
                    font-size: 18px;
                    line-height: 18px;
                    margin-top: 8px;
                    margin-bottom: 8px;
                }
            }
        </style>
HTML

    # Change button label and add open in new window button.
    my @button_actions_nodes
        = grep { $_->getAttribute('name') eq 'action_buttons' }
        @{ $tmpl->getElementsByTagName('setvarblock') };

    if (@button_actions_nodes) {

        # Button labels.
        my $button_labels_node
            = $tmpl->createElement( 'setvarblock', { name => 'null', } );
        $button_labels_node->innerHTML(
            q{
            <mt:if name="status" eq="2">
              <mt:setvar name="save_button_value" value="<__trans_section component="smartphoneoption"><__trans phrase="Publish"></__trans_section>">
              <mt:setvar name="save_button_title" value="<__trans_section component="smartphoneoption"><__trans phrase="Publish"><__trans phrase="Publish (s)"></__trans_section>">
            <mt:else>
              <mt:setvar name="save_button_value" value="<__trans_section component="smartphoneoption"><__trans phrase="Save"></__trans_section>">
              <mt:setvar name="save_button_title" value="<__trans_section component="smartphoneoption"><__trans phrase="Save (s)"></__trans_section>">
            </mt:if>
              <mt:setvar name="edit_button_value" value="<__trans_section component="smartphoneoption"><__trans phrase="Re-Edit"></__trans_section>">
              <mt:setvar name="edit_button_title" value="<__trans_section component="smartphoneoption"><__trans phrase="Re-Edit (e)"></__trans_section>">
        }
        );

        $tmpl->insertBefore( $button_labels_node, $button_actions_nodes[0] );
    }

    return 1;
}

1;
