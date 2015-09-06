# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package MT::App::CMS::Smartphone;
use strict;
use warnings;
use MT;
use base qw( MT::App::CMS );

{
    my %default_plugin_switch = map { $_ => 1 } qw(
        Enterprise.pack
        Commercial.pack
        Community.pack
        FacebookCommenters/plugin.pl
        feeds-app-lite/mt-feeds.pl
        Markdown/Markdown.pl
        Markdown/SmartyPants.pl
        mixiComment/mixiComment.pl
        MultiBlog/multiblog.pl
        SmartphoneOption
        spamlookup/spamlookup.pl
        spamlookup/spamlookup_urls.pl
        spamlookup/spamlookup_words.pl
        StyleCatcher
        Textile/textile2.pl
        TypePadAntiSpam
        WidgetManager/WidgetManager.pl
        WXRImporter
        DynamicMTML.pack
        FormattedText
    );

    no warnings qw( redefine );

    my $plugin_switch;
    my $__load_plugin = \&MT::__load_plugin;
    *MT::__load_plugin = sub {
        $plugin_switch ||= {
            %default_plugin_switch, %{ MT->config->SmartphonePluginSwitch },
        };
        return unless $plugin_switch->{ $_[5] };
        $__load_plugin->(@_);
    };

    my $__load_plugin_with_yaml = \&MT::__load_plugin_with_yaml;
    *MT::__load_plugin_with_yaml = sub {
        $plugin_switch ||= {
            %default_plugin_switch, %{ MT->config->SmartphonePluginSwitch },
        };
        return unless $plugin_switch->{ $_[2] };
        $__load_plugin_with_yaml->(@_);
    };
}

sub run_callbacks {

    # Override.
    # Because we should use MT::App::CMS instead of MT::App::CMS::Smartphone.
    my $app = shift;
    my ( $meth, @param ) = @_;
    $meth = 'MT::App::CMS::' . $meth unless $meth =~ m/::/;
    return $app->SUPER::run_callbacks( $meth, @param );
}

sub init_config {

    # Our plugins are not yet loaded. so add directive setting here.
    $_[0]->component('core')->registry(
        config_settings => 'SmartphonePluginSwitch' => {
            type    => 'HASH',
            default => {},
        },
    );
    $_[0]->component('core')
        ->registry( config_settings => 'SmartphoneAdminScript' =>
            { default => 'mt-sp.cgi', }, );
    $_[0]->SUPER::init_config(@_) or return;

    # Override AltTemplatePath config directive.
    MT->config( 'AltTemplatePath', '' );

    # Override AdminScript config directive.
    MT->config( 'AdminScript', MT->config->SmartphoneAdminScript );

    # Hide device switcher.
    MT->config( 'HideDeviceSwitcher', 1 );
}

1;
