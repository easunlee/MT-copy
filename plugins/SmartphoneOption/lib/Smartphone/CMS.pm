# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

use strict;
use Smartphone::Device;

package MT::Author;

sub widgets {

    # Override to fix widgets for smartphone.
    my $author = shift;

    my $device = Smartphone::Device->request_device
        || return $author->SUPER::widgets(@_);
    return $author->SUPER::widgets(@_) if $device->is_pc;

    my $app     = MT->instance;
    my $q       = $app->param;
    my $blog_id = $q->param('blog_id');
    $blog_id = '' unless defined $blog_id;
    my $mode = $app->mode;

    if (@_) {

        # Widgets not fixed?
        my $fixed_widgets = $device->registry( $app, 'fixed_widgets' )
            || return $author->SUPER::widgets(@_);

        # Merge widgets hash with updating hash.
        sub _recursive_merge_widgets {
            my ( $current, $updating ) = @_;
            foreach my $key ( keys %$updating ) {
                my $u = $updating->{$key};
                my $c = $current->{$key};

                if ( !defined($c) || ref($u) ne 'HASH' ) {

                    # Except for order because reordered to fix widgets.
                    $current->{$key} = $u if $key ne 'order';
                    next;
                }
                elsif ( ref $c eq 'HASH' ) {
                    _recursive_merge_widgets( $c, $u );
                }
            }
        }

        # If not hash, update directly.
        my ($updating) = @_;
        return $author->SUPER::smartphone_fixed_widgets(@_)
            if ref $updating ne 'HASH';

        # Merge with current hash.
        my $current = $author->SUPER::smartphone_fixed_widgets || {};
        _recursive_merge_widgets( $current, $updating );
        return $author->SUPER::smartphone_fixed_widgets($current);
    }

    my $current_widgets          = $author->SUPER::widgets;
    my $smartphone_fixed_widgets = $author->SUPER::smartphone_fixed_widgets();

    # Initialize fixed smartphone widgets.
    my $fixed_widgets = $device->registry( $app, 'fixed_widgets' )
        || return $current_widgets;
    my $blog_stats_tabs_white_list
        = $device->registry( $app, 'blog_stats_tabs_white_list' )
        || { entry => 1 };
    my $default_blog_stats_tab = $blog_stats_tabs_white_list->{_default}
        || 'entry';

    my $widgets_store = {};
    my $all_widgets = $app->registry('widgets') || {};

    # Context and scope.
    my ( $scope, $context );
    if ( $blog_id eq '' ) {
        $context = 'user';
        $scope = join( ':', $mode, $context, $app->user->id );
    }
    elsif ($blog_id) {
        $context = $app->blog->is_blog ? 'blog' : 'website';
        $scope = join( ':', $mode, 'blog', $blog_id );
    }
    else {
        $context = 'system';
        $scope = join( ':', $mode, $context );
    }

    # Compose widget store.
    my $order             = 1;
    my $fixed_widget_list = $fixed_widgets->{$context};

    $fixed_widget_list = [] if ref $fixed_widget_list ne 'ARRAY';

    foreach my $key (@$fixed_widget_list) {
        if ( my $widget = $all_widgets->{$key} ) {

            # Refer the original or widget entry.
            $key .= '-1' unless $widget->{singular};
            $widgets_store->{$scope}->{$key}
                = $smartphone_fixed_widgets->{$scope}->{$key}
                || $current_widgets->{$scope}->{$key}
                || {
                set => $widget->{set} || 'main',
                exists $widget->{param} ? ( param => $widget->{param} ) : (),
                };

            # Blog stats tab must be in white list.
            if ( $key eq 'blog_stats' ) {
                my $param = $widgets_store->{$scope}->{$key}->{param} || next;
                unless ( $blog_stats_tabs_white_list->{ $param->{tab} } ) {
                    $param->{tab} = $default_blog_stats_tab;
                }
            }

            # Reorder.
            $widgets_store->{$scope}->{$key}->{order} = $order++;
        }
    }

    # Save smartphone widgets.
    $author->SUPER::smartphone_fixed_widgets($widgets_store);
    $author->save();

    $widgets_store;
}

sub list_prefs {

    # Override to never save on Smartphone.
    my $author = shift;

    if ( my $device = Smartphone::Device->request_device ) {
        unless ( $device->is_pc ) {

            # Switch to smartphone_list_prefs.
            return $author->SUPER::smartphone_list_prefs(@_);
        }
    }

    $author->SUPER::list_prefs(@_);
}

package Smartphone::CMS;

use Smartphone::Util;
use Smartphone::Util::DateTime;

sub on_pre_run {
    my ( $cb, $app ) = @_;
    my $q       = $app->param;
    my $blog_id = $app->param('blog_id');

    # Handle only for MT::App::CMS instance.
    return 1 unless $app->isa('MT::App::CMS');

    # Join splited datetime.
    join_datetime_request_param($app);

    # Get the current device, nothing to do for PC.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # Redirect to user dashboard if in system scope methods.
    my $device_prefs = $device->registry( $app, 'prefs' ) || {};
    if ( $device_prefs->{system_scope_denied} ) {
        my $denied = 0;

        if ( !$blog_id && $app->mode eq 'dashboard' ) {

            # Allow user dashboard.
            $denied = defined $blog_id ? 1 : 0;
        }
        elsif ( !$blog_id ) {

            # Check white list.
            my $white_list
                = $device->registry( $app, 'system_methods_white_list' )
                || {};
            if ( !$white_list->{ $app->mode } ) {

                # Check if method requires login.
                my $methods        = $app->registry('methods') || {};
                my $method         = $methods->{ $app->mode };
                my $requires_login = 1;
                $requires_login = 0
                    if ref $method eq 'HASH'
                        && defined( $method->{requires_login} )
                        && !$method->{requires_login};

                $denied = 1 if $requires_login;
            }
        }

        if ($denied) {

            # Force to user dashboard.
            $app->param( 'blog_id', '' );
            return $app->return_to_dashboard(
                redirect      => 1,
                device_denied => 1
            );
        }
    }

    # Never allow quicksearch for search blog.
    # Because it will redirect to cfg_prefs.
    $app->param( 'quicksearch', 0 )
        if $app->mode eq 'search_replace' && $q->param('_type') eq 'blog';

    # Unable normal richtext.
    # filter_key=richtext is changed to _richtext.
    if ( my $convert_breaks = $q->param('convert_breaks') ) {
        $app->param( 'convert_breaks', 'richtext' )
            if $convert_breaks eq '_richtext';
    }

    1;
}

sub on_template_param {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $mode    = $app->mode;
    my $q       = $app->param;
    my $type    = $q->param('_type');
    my $blog_id = $q->param('blog_id');

    # Do nothing for widgets and includes.
    return
        if $param->{template_filename}
            && $param->{template_filename}
            =~ m!^(widget/|include/|dialog/asset_options_)!;

    # Do nothing more if already flagged.
    return if request_cache->{template_param_handled};

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;

    # Add switching view menu.
    if ( !$app->config('HideDeviceSwitcher')
        && ( my $switchable_to = $device->switchable_to ) )
    {

        # Template slots defined in on_template_param_header.
        $param->{switchable_device}
            = plugin->translate( '[_1] View', $switchable_to->label );
        $param->{switchable_device_name} = $switchable_to->label;

        # URL rule: From pc or method is not GET, to dashbaord by context.
        # Never link to System Dashboard!
        my %args
            = ( $app->request_method eq 'GET' && $switchable_to->is_pc )
            ? $app->param_hash
            : (
            __mode => 'dashboard',
            $blog_id ? ( blog_id => $blog_id ) : (),
            );
        $args{_device} = $switchable_to->key;
        $param->{switchable_device_url} = $app->uri( args => \%args );
    }

    return if $device->is_pc;

    # Params.
    $param->{device_name} = $device->label;
    $param->{screen_class}
        = join( ' ', $param->{screen_class} || '', $device->screen_classes );

    # Hide administration links.
    my $device_prefs = $device->registry( $app, 'prefs' ) || {};
    if ( $device_prefs->{hide_administer_access} ) {

        # Restrict scope selector and widgets.
        $param->{"can_$_"} = 0
            for qw/create_blog create_website access_overview/;
    }

    # HTML meta, css and javascript lines for smartphone.
    my ( %meta, @csses, @javascripts );

    my $html_head = $device->registry( $app, 'html_head' ) || {};
    my @ordered_html_head
        = sort { ( $a->{order} || 1000 ) <=> ( $b->{order} || 1000 ); }
        values %$html_head;

    my @html;
    foreach my $element (@ordered_html_head) {
        if ( my $condition = $element->{condition} ) {

            # Filter by condition.
            $condition = MT->handler_to_coderef($condition)
                if ref $condition ne 'CODE';

            next
                if ref $condition eq 'CODE'
                    && !$condition->( $app, $mode, $type );
        }

        if ( my $html = $element->{html} ) {
            push @html, $html;
        }
        elsif ( my $file = $element->{file} ) {

            # File type detection.
            if ( !$element->{type} && $file =~ /\.([a-z0-9]+)$/i ) {
                $element->{type} = $1;
            }

            my $plugin = $element->{plugin};
            if ( $plugin && $file !~ m!^(/|https?://|://)!i ) {
                $file = plugin_static_url( $plugin, $file, $element );
            }

            # Output by filetype.
            if ( $element->{type} eq 'css' ) {
                push @html, qq{<link rel="stylesheet" href="$file" />};
            }
            elsif ( $element->{type} eq 'js' ) {
                push @html,
                    qq{<script type="text/javascript" charset="UTF-8" src="$file"></script>};
            }
            elsif ( $element->{type} eq 'link' ) {
                my $rel = $element->{rel};
                push @html, qq{<link rel="$rel" href="$file" />} if $rel;
            }
        }
    }

    $param->{js_include} ||= '';
    $param->{js_include} .= join( "\n", @html );

    # Filter menus.
    my @new_top_nav_loop;
    if ( my $top_nav_loop = $param->{top_nav_loop} ) {
        if ( my $menus_white_list
            = $device->registry( $app, 'menus_white_list' ) )
        {
            my $testing = sub {
                my ($nav) = @_;
                my $filter = $menus_white_list->{ $nav->{id} } || return 0;
                if ( ref $filter eq 'HASH' ) {
                    if ( $filter->{uploadable} && !$device->uploadable ) {
                        return 0;
                    }
                }

                1;
            };

            foreach my $top_nav (@$top_nav_loop) {
                next unless &$testing($top_nav);

                my @new_sub_nav_loop;
                if ( my $sub_nav_loop = $top_nav->{sub_nav_loop} ) {
                    foreach my $sub_nav ( @{ $top_nav->{sub_nav_loop} } ) {
                        next unless &$testing($sub_nav);
                        push @new_sub_nav_loop, $sub_nav;
                    }

                }

                # Skip if no sub menus.
                next unless @new_sub_nav_loop;

                $top_nav->{sub_nav_loop} = \@new_sub_nav_loop;
                push @new_top_nav_loop, $top_nav;
            }
        }

        $param->{top_nav_loop} = \@new_top_nav_loop;
    }

    # Device denied.
    # Template slots defined in on_template_source_header.
    $param->{device_denied} = $app->param('device_denied') ? 1 : 0;

    # Uploadable.
    $param->{can_upload} &&= $device->uploadable;

    # Never link to commenter.
    delete $param->{commenter_url};

    # Flag handled.
    request_cache->{template_param_handled} = 1;
}

sub on_template_source_header {
    my ( $cb, $app, $rtmpl, $file ) = @_;
    my $q = $app->param;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # Insert alert if the method not supported for the device.
    my $methods = $device->registry( $app, 'supported_methods' );
    my $types = $device->registry( $app, 'supported_methods', '_types' )
        || {};

    if ($methods) {
        my $default = $methods->{_default} || 0;
        my $method  = $app->mode;
        my $type    = $q->param('_type') || '';
        $method .= '.' . $type if $type;

        my $supported
            = defined( $types->{$type} )     ? $types->{$type}
            : defined( $methods->{$method} ) ? $methods->{$method}
            :                                  $default;

        if ( ref $supported eq 'HASH' ) {
            if ( $supported->{uploadable} && !$device->uploadable ) {
                $supported = 0;
            }
        }

        if ( !$supported ) {
            $$rtmpl = q{
                <mt:setvarblock name="system_msg" prepend="1">
                    <div id="alert-msg-block">
                        <mtapp:statusmsg
                           id="smartphone-not-supported"
                           class="alert">
                          <__trans_section component="smartphoneoption">
                          <mt:if name="device_name">
                              <__trans phrase="This function is not supported by [_1]." params="<mt:var name='device_name'>">
                          <mt:else>
                              <__trans phrase="This function is not supported by your browser.">
                          </mt:if>
                          </__trans_section>
                        </mtapp:statusmsg>
                    </div>
                </mt:setvarblock>
            } . $$rtmpl;
        }
    }

    # Insert alert device denied.
    $$rtmpl = q{
        <mt:if name="device_denied">
            <mt:setvarblock name="system_msg" prepend="1">
                <div id="alert-msg-block">
                    <mtapp:statusmsg
                       id="smartphone-denied"
                       class="error">
                      <__trans_section component="smartphoneoption">
                      <__trans phrase="This function is not supported by [_1]." params="<mt:var name='device_name'>">
                      </__trans_section>
                    </mtapp:statusmsg>
                </div>
            </mt:setvarblock>
        </mt:if>
    } . $$rtmpl;

    1;
}

sub on_template_param_header {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Insert device switcher.
    my $hide_device_switcher = $app->config('HideDeviceSwitcher') || 0;

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 unless $device->switchable_to;

    # Insert link to switch view.
    if ( $device->is_pc ) {

        # Nothing to do if switcher should be hidden.
        return if $hide_device_switcher;

        my @author_name_nodes
            = grep { $_->getAttribute('name') eq 'author_name' }
            @{ $tmpl->getElementsByTagName('if') };

        if (@author_name_nodes) {
            my $switch_device_node = $tmpl->createElement( 'if',
                { name => 'switchable_device', } );
            $switch_device_node->innerHTML(
                q{
                <__trans_section component="smartphoneoption">
                <div id="switch-device">
                    <a href="<mt:var name='switchable_device_url'>">
                        <__trans phrase="Mobile Dashboard">
                    </a>
                </div>
                </__trans_section>
            }
            );

            $tmpl->insertBefore( $switch_device_node, $author_name_nodes[0] );

            # Add style.
            my $css_node = $tmpl->createElement(
                'setvarblock',
                {   name   => 'js_include',
                    append => 1,
                }
            );
            $css_node->innerHTML(
                q{
                <style type="text/css">
                    #switch-device {
                        position: absolute;
                        top: 0px;
                        width: 30%;
                        left: 35%;
                        z-index: 510;
                        height: 50px;
                        padding: 0px;
                        line-height: 50px;
                        background: -webkit-gradient(linear, left top, left bottom, from(#FFD900), to(#F8B500));
                        border: 1px solid #f8b500;
                        border-top: 0;
                        border-bottom-left-radius: 8px;
                        border-bottom-right-radius: 8px;
                        box-shadow: 1px 1px 2px #666;
                    }

                    #switch-device a {
                        display: block;
                        color: #2b2b2b;
                        font-size: 18px;
                        font-weight: bold;
                        text-align: center;
                        text-decoration: none;
                        border-bottom-left-radius: 8px;
                        border-bottom-right-radius: 8px;
                    }
                </style>
            }
            );
            my $child_nodes = $tmpl->childNodes;
            unshift @$child_nodes, $css_node;
        }
    }
    else {

        # For smartphone.
        my @logout_nodes = grep { $_->getAttribute('name') eq 'can_logout' }
            @{ $tmpl->getElementsByTagName('if') };

        if (@logout_nodes) {

            # Required li element in order to style for smartphone...
            my $switch_device_node = $tmpl->createElement(
                $hide_device_switcher ? 'unless' : 'if',
                { name => 'switchable_device', }
            );

            my $inner_html = q{<li id="switch-device">};
            $inner_html .= q{
                <a href="<mt:var name='switchable_device_url'>">
                    <mt:var name="switchable_device" escape="html">
                </a>
            } if !$hide_device_switcher;
            $inner_html .= q{</li>};

            $switch_device_node->innerHTML($inner_html);
            $tmpl->insertAfter( $switch_device_node, $logout_nodes[0] );
        }
    }

    1;
}

sub on_template_output_footer {
    my ( $cb, $app, $rtmpl, $param, $template ) = @_;
    my $q    = $app->param;
    my $mode = $app->mode || '';
    my $type = $q->param('_type') || '';

    # Request device.
    my $device = Smartphone::Device->request_device || return 1;
    return 1 if $device->is_pc;

    # Call mtSmartphone after all jquery calling to effort to jquery.ui.
    # Shoud be fixed not to use template_output.
    my $jquery = plugin->translate_templatized(<<"JQ");
<script type="text/javascript">
/* <![CDATA[ */
jQuery(function() {
    jQuery.mtSmartphone({
        entryIframeMessage: '<__trans phrase="Rich text editor is not supported by your browser. Continue with  HTML editor ?" escape="js">',
        templateIframeMessage: '<__trans phrase="Syntax highlight is not supported by your browser. Disable to continue ?" escape="js">',
        request: {
            mode: '$mode',
            type: '$type'
        }
    });
});
/* ]]> */
</script>
JQ

    $$rtmpl =~ s!</body>!$jquery</body>!i;

    1;
}

sub on_template_param_login {
    my ( $cb, $app, $param, $tmpl ) = @_;

    # Filter device_denied query param.
    $param->{query_params} = [ grep { $_->{name} ne 'device_denied' }
            @{ $param->{query_params} } ];

    1;
}

sub select_formatted_text {
    my $app = shift;

    my $blog = $app->blog or $app->return_to_dashboard( redirect => 1 );

    return $app->permission_denied()
        unless $app->can_do('access_to_formatted_text_list');

    my $formatted_text_class = $app->model('formatted_text');
    my $hasher               = sub {
        my ( $obj, $row, %param ) = @_;
        %$row = %{ $obj->get_values };
        $row;
    };

    $app->listing(
        {   terms => { blog_id => $blog->id },
            args  => { sort    => 'id', direction => 'descend' },
            type     => 'formatted_text',
            code     => $hasher,
            template => $app->component('SmartphoneOption')
                ->load_tmpl('cms/dialog/select_formatted_text.tmpl'),
            params => {
                blog_id          => $blog->id,
                search_label     => $formatted_text_class->class_label_plural,
                search_type      => 'formatted_text',
                panel_searchable => 1,
                object_type      => 'formatted_text',
            },
        }
    );
}

1;
