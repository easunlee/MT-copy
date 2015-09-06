# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::L10N::fr;

use strict;
use base 'Smartphone::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## plugins/SmartphoneOption/config.yaml
	'Provides an iPhone, iPad and Android touch-friendly UI for Movable Type. Once enabled, navigate to your MT installation from your mobile to use this interface.' => 'Fournit une interface tactile iPhone, iPad et Android pour Movable Type. Une fois activé, connectez-vous à votre installation MT depuis votre mobile pour utiliser cette interface.',
	'iPhone' => 'iPhone',
	'iPad' => 'iPad',
	'Android' => 'Android',
	'PC' => 'PC',

## plugins/SmartphoneOption/lib/Smartphone/CMS.pm
	'This function is not supported by [_1].' => 'Cette fonctionnalité n\'est pas supportée par [_1]',
	'This function is not supported by your browser.' => 'Cette fonctionnalité n\'est pas supportée par votre navigateur',
	'Mobile Dashboard' => 'Tableau de bord Mobile',
	'Rich text editor is not supported by your browser. Continue with  HTML editor ?' => 'L\'editeur de texte enrichi n\'est pas supporté par votre navigateur. Continuer avec l\'editeur HTML ?',
	'Syntax highlight is not supported by your browser. Disable to continue ?' => 'Le surlignage de syntaxe n\'est  pas supporté par votre navigateur. Désactiver pour continuer ?',
	'[_1] View' => 'Vue [_1]',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Entry.pm
	'Re-Edit' => 'Rééditer',
	'Re-Edit (e)' => 'Rééditer (e)',
	'Format' => 'Format',
	'Rich Text(HTML mode)' => 'Texte enrichi (Mode HTML)',
	'Publish' => 'Publier',
	'Publish (s)' => 'Publier (s)',
	'Save' => 'Sauvegarder',
	'Save (s)' => 'Sauvegarder (s)',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Listing.pm
	'Select All' => 'Sélectionner tout',
	'Filters which you created from PC.' => 'Filtres créés depuis votre PC',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Search.pm
	'Search [_1]' => 'Rechercher [_1]',

## plugins/SmartphoneOption/smartphone.yaml
	'Entry:[_1] Page:[_2]' => 'Note :[_1] Page :[_2]',
	'Smartphone Main' => 'PDA Principale',
	'Smartphone Sub' => 'PDA Suite',
	'Unpublish' => 'Dépublier',
	'Entry:[_1] Page:[_2]' => '´Note :[_1] PAge :[_2]',

## plugins/SmartphoneOption/smartphone_list_properties.yaml
	'by [_1] on [_2]' => 'par [_1] sur [_2]',

);

1;
