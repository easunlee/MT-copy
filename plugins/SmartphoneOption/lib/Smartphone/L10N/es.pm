# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::L10N::es;

use strict;
use base 'Smartphone::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (
## plugins/SmartphoneOption/config.yaml
	'Provides an iPhone, iPad and Android touch-friendly UI for Movable Type. Once enabled, navigate to your MT installation from your mobile to use this interface.' => 'Provee a Movable Type un interfaz táctil especialmente adaptado a iPhone, iPad y Android.',
	'iPhone' => 'iPhone',
	'iPad' => 'iPad',
	'Android' => 'Android',
	'PC' => 'PC',

## plugins/SmartphoneOption/lib/Smartphone/CMS.pm
	'This function is not supported by [_1].' => 'Esta función no está soportada por [_1]',
	'This function is not supported by your browser.' => 'Esta función no está soportada por su navegador.',
	'Mobile Dashboard' => 'Panel de Control - Móvil',
	'Rich text editor is not supported by your browser. Continue with  HTML editor ?' => 'El editor de texto con formato no está soportado por el navegador. ¿Continuar con el editor HTML?',
	'Syntax highlight is not supported by your browser. Disable to continue ?' => 'El coloreado de sintaxis no está soportado por el navegador. ¿Desactivar para continuar? ',
	'[_1] View' => 'Vista [_1]',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Entry.pm
	'Re-Edit' => 'Re-editar',
	'Re-Edit (e)' => 'Re-editar (e)',
	'Format' => 'Formato',
	'Rich Text(HTML mode)' => 'Texto con formato (modo HTML)',
	'Publish' => 'Publicar',
	'Publish (s)' => 'Publicar (s)',
	'Save' => 'Guardar',
	'Save (s)' => 'Guardar (s)',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Listing.pm
	'Select All' => 'Seleccionar todo',
	'Filters which you created from PC.' => 'Filtros creados en el PC.',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Search.pm
	'Search [_1]' => 'Buscar [_1]',

## plugins/SmartphoneOption/smartphone.yaml
	'Entry:[_1] Page:[_2]' => 'Entrada:[_1] Página:[_2]',
	'Smartphone Main' => 'Móvil Principal',
	'Smartphone Sub' => 'Móvil Secundario',
	'Unpublish' => 'Despublicar',
	'Entry:[_1] Page:[_2]' => 'Entrada:[_1] Página:[_2]',

## plugins/SmartphoneOption/smartphone_list_properties.yaml
	'by [_1] on [_2]' => 'por [_1] en [_2]',

);

1;
