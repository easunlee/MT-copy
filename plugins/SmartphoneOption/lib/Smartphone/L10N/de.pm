# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::L10N::de;

use strict;
use base 'Smartphone::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## plugins/SmartphoneOption/config.yaml
	'Provides an iPhone, iPad and Android touch-friendly UI for Movable Type. Once enabled, navigate to your MT installation from your mobile to use this interface.' => 'Touch-Oberfläche für iPhone, iPad und Android. Wird automatisch angezeigt, wenn Sie Movable Type von Ihrem Mobilgerät aus aufrufen.',
	'iPhone' => 'iPhone',
	'iPad' => 'iPad',
	'Android' => 'Android',
	'PC' => 'PC',

## plugins/SmartphoneOption/lib/Smartphone/CMS.pm
	'This function is not supported by [_1].' => 'Diese Funktion wird von [_1] nicht unterstützt.',
	'This function is not supported by your browser.' => 'Diese  Funktion wird von Ihrem Browser nicht unterstützt.',
	'Mobile Dashboard' => 'Mobile Übersichtsseite',
	'Rich text editor is not supported by your browser. Continue with  HTML editor ?' => 'Der grafische Editor kann mit diesem Browser nicht verwendet werden. Zur HTML-Ansicht wechseln?',
	'Syntax highlight is not supported by your browser. Disable to continue ?' => 'Syntax-Hervorhebung kann mit diesem Browser nicht verwendet werden. Deaktivieren und fortsetzen?',
	'[_1]' => '[_1]-Ansicht',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Entry.pm
	'Re-Edit' => 'Erneut bearbeiten',
	'Re-Edit (e)' => 'Erneut bearbeiten (e)',
	'Format' => 'Format',
	'Rich Text(HTML mode)' => 'Grafischer Editor(HTML-Modus)',
	'Publish' => 'Veröffentlichen',
	'Publish (s)' => 'Veröffentlichen (s)',
	'Save' => 'Speichern',
	'Save (s)' => 'Speichern (s)',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Listing.pm
	'Select All' => 'Alle auswählen',
	'Filters which you created from PC.' => 'Am Desktop-PC angelegte Filter',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Search.pm
	'Search [_1]' => '[_1] suchen',

## plugins/SmartphoneOption/smartphone.yaml
	'Entry:[_1] Page:[_2]' => 'Eintrag:[_1] Seite:[_2]',
	'Smartphone Main' => 'Smartphone Main',
	'Smartphone Sub' => 'Smartphone Sub',
	'Unpublish' => 'Nicht mehr veröffentlichen',
	'Entry:[_1] Page:[_2]' => 'Eintrag:[_1] Seite:[_2]',

## plugins/SmartphoneOption/smartphone_list_properties.yaml
	'by [_1] on [_2]' => 'von [_1] zu [_2]',

);

1;
