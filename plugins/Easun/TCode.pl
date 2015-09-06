#------------------------------------------------------------------
#	Copyright (c) 2007, Lee, Joon (http://alogblog.com/)
#	This code is released under a Creative Commons License.
#		(http://creativecommons.org/licenses/by-nc-sa/2.5/)
#------------------------------------------------------------------
package MT::Plugin::Easun::TCode;

use strict;
use base qw(MT::Plugin);
use vars qw( $VERSION );
$VERSION = '4.0.00';

my $magicKey = "This is Easun's Blog. your ping is to be moderated, so please dont't send repeatedly";
my $PENDING = '__PENDING__';

my $check_update = qq[<script type="text/javascript" src="http://alogblog.com/movabletype/plugins/docs/check-update.cgi?ccode=$VERSION"></script>];
my $plugin = MT::Plugin::Easun::TCode->new({
	id => 'tcode',
	key => 'tcode',
	name => 'TCode',
	description => "<MT_TRANS phrase='For blocking spam trackbacks, it adds an additional code to the original trackback ID, and obfuscates it with Javascript.'>$check_update",
	version => $VERSION,
	plugin_link => 'http://alogblog.com/movabletype/plugins/ccode_and_tcode_for_blocking_commenttrackback_spam_for_mt_32/',
	author_name => 'Lee, Joon(&#xC774;&#xACBD;&#xC900;)',
	author_link => 'http://alogblog.com/movabletype/plugins/',
	#icon => 'images/alogblog.gif',
	#l10n_class => 'alogblog::CTCode::L10N',
});
MT->add_plugin($plugin);

my $mt_ping = \&MT::App::Trackback::ping;
*MT::App::Trackback::ping = \&alogblog_ping;
MT->add_callback('MT::App::CMS::AppTemplateSource.edit_category', 2, $plugin, \&alogblog_tcode_template);
MT->add_callback('MT::App::CMS::AppTemplateParam.edit_category', 2, $plugin, \&alogblog_tcode_param);
MT->add_callback('TBPingFilter', 2, $plugin, \&alogblog_pingfilter);

#my $mt_entry_tb_data = \&MT::Template::Tags::Ping::_hdlr_entry_tb_data;
sub init_registry {
	my $plugin = shift;
	$plugin->registry({
		tags => {
			function => {
				'EntryTrackbackID' => \&alogblog_entry_tb_id,
				'EntryTrackbackLink' => \&alogblog_entry_tb_link,
				'CategoryTrackbackLink' => \&alogblog_category_tb_link,
			 	#'EntryTrackbackData' => \&alogblog_entry_tb_data,
			},
		}
	});
}
sub alogblog_tcode_param {
	my ($cb, $app, $param) = @_;
	my $q = $app->param;
	my $id = $q->param('id');

	require MT::Trackback;
	my $tb = MT::Trackback->load({ category_id => $id });
	if ($tb) {
		my $path = $app->config('CGIPath');
		$path .= '/' unless $path =~ m!/$!;
		my $script = $app->config('TrackbackScript');

		my $bn = unpack('S', substr($tb->created_on, -4, 2));
		my $cr = unpack('S', substr($tb->created_on, -2));
		my $ts = $bn.$cr;

		$param->{tb_tcode_url} = $path . $script . '/' . $tb->id . '.' . $ts;
		if ($param->{tb_passphrase} = $tb->passphrase) {
			$param->{tb_tcode_url} .= '/' . MT::Util::encode_url($param->{tb_passphrase});
		}
	}
}

sub alogblog_tcode_template {
        my ($cb, $app, $template) = @_;

	$$template =~ s/TMPL_VAR NAME=TB_URL/TMPL_VAR NAME=TB_TCODE_URL/;
        $$template;
}

sub alogblog_entry_tb_data {
	#my $data = $Core::MT::Template::Tags::Ping::_hdlr_entry_tb_data;
	#$data =~ s/(trackback:ping=)"(.*?)"/$1"$2.$magicKey"/;
	#return $data;
}

sub alogblog_category_tb_link {
    my($ctx, $args) = @_;
    my $cat = $_[0]->stash('category') || $_[0]->stash('archive_category');
    if (!$cat) {
        my $cat_name = $args->{category}
            or return $ctx->error('<$MTCategoryTrackbackLink$> must be ' .
                "used in the context of a category, or with the 'category' " .
                "attribute to the tag.");
        $cat = MT::Category->load({ label => $cat_name,
                                    blog_id => $ctx->stash('blog_id') })
            or return $ctx->error("No such category '$cat_name'");
    }
	require MT::Trackback;
	my $tb = MT::Trackback->load({ category_id => $cat->id });
	if ($tb) {
	    my $cfg = MT::ConfigMgr->instance;
    	my $path = $cfg->CGIPath;
		$path .= '/' unless $path =~ m!/$!;
		$path .= $cfg->TrackbackScript . '/' . $tb->id;

		if($args->{nocode} eq '1') {
			return $path . '.' . $magicKey;
		} elsif($args->{nocode} eq '2') {
			return $path;
		}

		my $bn = unpack('S', substr($tb->created_on, -4, 2));
		my $cr = unpack('S', substr($tb->created_on, -2));
		my $ts = $bn.$cr;
		$path .= '.';

		require Easun::Obfuscator;
		if($_[1]->{hidden}) {
			Easun::Obfuscator::munge('', $ts, '__MTTBLINK__', $path, 1);
		} else {
			$path . Easun::Obfuscator::munge('', $ts, '__MTTBLINK__', $path);
		}
	}
}

sub alogblog_entry_tb_id {
	my $e = $_[0]->stash('entry')
	        or return $_[0]->_no_entry_error('MTEntryTrackbackID');
	my $args = $_[1];

	require MT::Trackback;
	my $tb = MT::Trackback->load({ entry_id => $e->id }) or return '';

	if($args->{nocode} eq '1') {
		return $tb->id . '.' . $magicKey;
	} elsif($args->{nocode} eq '2') {
		return $tb->id;
	}

	my $bn = unpack('S', substr($tb->created_on, -4, 2));
	my $cr = unpack('S', substr($tb->created_on, -2));

	require Easun::Obfuscator;
	Easun::Obfuscator::munge('', $tb->id . ".$bn$cr", '__MTTBID__', '', $_[1]->{hidden});
}

sub alogblog_entry_tb_link {
	my $e = $_[0]->stash('entry')
		or return $_[0]->_no_entry_error('MTEntryTrackbackLink');
	my $args = $_[1];

	require MT::Trackback;
	my $tb = MT::Trackback->load({ entry_id => $e->id }) or return '';
	my $cfg = MT::ConfigMgr->instance;
	my $path = $cfg->CGIPath;
	$path .= '/' unless $path =~ m!/$!;
	$path = $path . $cfg->TrackbackScript . '/' . $tb->id;

	if($args->{nocode} eq '1') {
		return $path . '.' . $magicKey;
	} elsif($args->{nocode} eq '2') {
		return $path;
	}

	my $bn = unpack('S', substr($tb->created_on, -4, 2));
	my $cr = unpack('S', substr($tb->created_on, -2));
	my $ts = $bn.$cr;
	$path .= '.';

	require Easun::Obfuscator;
	if($_[1]->{hidden}) {
		Easun::Obfuscator::munge('', $ts, '__MTTBLINK__', $path, 1);
	} else {
		$path . Easun::Obfuscator::munge('', $ts, '__MTTBLINK__', $path);
	}
}

sub alogblog_ping {
	my $app = shift;
	my($q,$tb_id, $pass, $unpacked_value);

	$q = $app->{query};
	($tb_id, $pass) = $app->_get_params;

	return $app->_response(Error =>
		$app->translate("Invalid TrackBack ID '[_1]'", $tb_id)) unless($tb_id && index($tb_id, '.') > 0);
	($tb_id, $unpacked_value) = split /\./, $tb_id;

	my $tb = MT::Trackback->load($tb_id)
		or return $app->_response(Error =>
			$app->translate("Invalid TrackBack ID '[_1]'", $tb_id));

	if($unpacked_value eq $magicKey) {
		my $name = $q->param('blog_name');
		$q->param('blog_name', $PENDING . $name);
	} else {
		my $bn = unpack('S', substr($tb->created_on, -4, 2));
		my $cr = unpack('S', substr($tb->created_on, -2));

		return $app->_response(Error => $app->translate("Invalid TrackBack ID '[_1]'", $tb_id)) if($unpacked_value ne "$bn$cr");
	}
	$q->param('tb_id', $tb_id);
	$q->param('pass', $pass);

	&$mt_ping($app, @_);
}

sub alogblog_pingfilter {
	my($eh, $app, $ping) = @_;

	if($ping->blog_name =~ /^${PENDING}(.*)$/) {
		$ping->blog_name($1);
		$ping->visible(0);
	}
	return 1;
}

1;
