# Movable Type (r) (C) 2001-2013 Six Apart, Ltd. All Rights Reserved.
# This code cannot be redistributed without permission from www.sixapart.com.
# For more information, consult your Movable Type license.
#
# $Id$

package Smartphone::L10N::ja;

use strict;
use base 'Smartphone::L10N::en_us';
use vars qw( %Lexicon );

## The following is the translation table.

%Lexicon = (

## plugins/SmartphoneOption/config.yaml
	'Provides an iPhone, iPad and Android touch-friendly UI for Movable Type. Once enabled, navigate to your MT installation from your mobile to use this interface.' => 'iPhone, iPad, Android などのタッチ操作に適したMovable Typeのユーザーインターフェースを提供します。プラグインを有効にして、端末からアクセスしてください。',
	'iPhone' => 'iPhone',
	'iPad' => 'iPad',
	'Android' => 'Android',
	'PC' => 'PC',

## plugins/SmartphoneOption/extlib/Image/ExifTool/MIFF.pm

## plugins/SmartphoneOption/lib/Smartphone/CMS.pm
	'This function is not supported by [_1].' => 'この機能は、[_1]に対応していません。',
	'This function is not supported by your browser.' => 'この機能は、お使いのブラウザに対応していません。',
	'Mobile Dashboard' => 'モバイルダッシュボード',
	'Rich text editor is not supported by your browser. Continue with  HTML editor ?' => 'この機能は、お使いのブラウザに対応していません。',
	'Syntax highlight is not supported by your browser. Disable to continue ?' => 'お使いのブラウザは、コードのハイライト表示に対応していません。無効にして編集しますか？',
	'[_1] View' => '[_1]表示',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Entry.pm
	'Re-Edit' => '再編集する',
	'Re-Edit (e)' => '再編集する (e)',
	'Rich Text(HTML mode)' => 'リッチテキスト(HTMLモード)',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Listing.pm
	'All' => '全て',
	'Filters which you created from PC.' => 'PCで作成したフィルタが表示されます',

## plugins/SmartphoneOption/lib/Smartphone/CMS/Search.pm
	'Search [_1]' => '[_1]の検索',

## plugins/SmartphoneOption/smartphone.yaml
	'to [_1]' => 'to [_1]',
	'Smartphone Main' => 'Smartphone Main',
	'Smartphone Sub' => 'Smartphone Sub',

## plugins/SmartphoneOption/tmpl/cms/dialog/select_formatted_text.tmpl
	'No boilerplate could be found.' => '定型文が見つかりません。',

);

1;
