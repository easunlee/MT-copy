# Movable Type plugin for comment titles to MT4
# http://mt-hacks.com/commenttitles.html

package MT::Plugin::CommentAgent;
use strict;
use base 'MT::Plugin';
use MT::Template::Context;
use vars qw($VERSION);
$VERSION = '1.00';
use MT;

my $plugin = MT::Plugin::CommentAgent->new({
    name => 'Comment Agent',
    description => "Adds 3 columns to the Comments table as 'remote_id' , 'remote_service' and  'agent' for DUOSHUO add on.",
	doc_link => "http://easun.org/",
	plugin_link => "http://easun.org/",
	author_name => "Easun Lee",
	author_link => "http://easun.org/",
       version => $VERSION,
	schema_version => '1.05',
});
MT->add_plugin($plugin);

sub instance {
	$plugin;
}

sub init_registry {
	my $component = shift;
	my $reg = {
		'object_types' => {
			'comment' => {
				'agent' => 'string(255)',
				'remote_id' => 'string(50)',
				'remote_service'=> 'string(50)',
			},
		},
		'callbacks' => {
			'MT::Comment::pre_save' => \&pre_save,
		},
        'tags' => {
            'function' => {
                'CommentAgent' => \&comment_agent,
                'CommentRemoteID' => \&comment_remote_id,
                'CommentServiceName' => \&comment_service_name,
            },
        },
	};
	$component->registry($reg);
}

sub pre_save {
	my ($cb, $comment, $orig_comment) = @_;
	my $app = MT->instance;
	my $q = $app->{query};
	return if !($app->can('param')); 
	return if ($comment->id); 
	return if ($comment->agent); 
	#return if !($q->param('agent'));
	$comment->agent($app->get_header('User-Agent')); #---->
	return 1;
}

sub comment_agent {
	my $ctx = shift;
	my $args = shift;
	my $comment = $ctx->stash('comment');
	my $agent;
	if ($comment->id) {
		$agent = $comment->agent;
	} 
#	else {
#		my $app = MT->instance;
#		$agent = $app->get_header('User-Agent') ;
#	}
#	if (!$agent && ($ctx->var('body_class') eq 'mt-comment-confirmation') ) {
#		my $app = MT->instance;
#		$agent = $app->get_header('User-Agent') ;
#	}
	return $agent || '';
}

sub comment_remote_id {
	my $ctx = shift;
	my $args = shift;
	my $comment = $ctx->stash('comment');
	my $remote_id;
	if ($comment->id) {
		$remote_id = $comment->remote_id;
	} 
	return $remote_id ||  0 ;
}

sub comment_service_name {
	my $ctx = shift;
	my $args = shift;
	my $comment = $ctx->stash('comment');
	my $service_name;
	if ($comment->id) {
		$service_name = $comment->remote_service;
	} 
	#$service_name = 'DuoShuo' if ($service_name eq 'DUOSHUO'); 
	return $service_name ||  'mt';
}

1;
