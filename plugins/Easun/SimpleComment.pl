# SimpleComment 0.01 Copyright 2006 EasunLee Easun.org
# SimpleComment 0.12 Copyright 2012 EasunLee Easun.org
# A Simple plugin for Anti-Comment-SPAM plugin for Movable Type 3.*
#
# Copyright 2012 EasunLee Easun.org
# http://easun.org/
# Using this software signifies your acceptance of the license
# file that accompanies this software.
#
# Installation and usage instructions can be found at
# http://easun.org/archives/mt_plugin/

package MT::Plugin::Easun::SimpleComment;

use strict;
use warnings;
use MT;
use MT::Template::Context;

use vars qw($MYNAME $VERSION $DEBUG );
$MYNAME = 'SimpleComment';
$VERSION = "0.12";
$DEBUG = 0;

# my $_SimpleCommentKey  = 'easun';
# my $_SimpleCommentKeyValue = 'Go/and/down/easun.org/ossu/perl/exit/spamisbad/SimpleComment Random template modules Include plugin for Movable Type By EasunLee';


#if (MT->version_number >= 3) {
        use MT::Plugin;
        my $plugin;
        $plugin = new MT::Plugin(
             {
              name => '<MT_TRANS phrase="SimpleComment">',
              version => $VERSION,
              id => lc $MYNAME,
              key => lc $MYNAME,
              description => '<MT_TRANS phrase="A Simple plugin for Anti-Comment-SPAM plugin for Movable Type By Easun.org">',
              doc_link => 'http://easun.org/archives/mt_plugin/',
              author_name => '<MT_TRANS phrase="EasunLee">',
              author_link => 'http://easun.org/blog/',
              l10n_class => 'Easun::L10N',
              icon => 'easun.ico',
              blog_config_template => 'config.tmpl',
              settings => new MT::PluginSettings([
                       [ 'SimpleCommentKey', { Default => undef, scope => 'blog' } ],
                       [ 'SimpleCommentKeyValue', { Default => undef, scope => 'blog' } ],
              ]),

              }
            );
        MT->add_callback('CommentThrottleFilter', 2, $plugin, \&_hdlr_easun_comment_filter);
        MT->add_plugin($plugin);

#}

MT::Template::Context->add_tag(SimpleCommentJS =>  \&_mt_tag_SimpleCommentJS );
MT::Template::Context->add_tag(SimpleCommentinFormKey =>  \&_mt_tag_SimpleCommentinFormKey );
MT::Template::Context->add_tag(SimpleCommentQueryString =>  \&_mt_tag_SimpleCommentQueryString );
MT::Template::Context->add_global_filter(EStrim => \&_hdlr_easun_html_reduce);
MT::Template::Context->add_global_filter(Gravatar => \&_hdlr_gravatar_url);
### ##################################################
#  return 0 means spam [CommentThrottleFilter] , as
#  "Too many comments have been submitted from you in a short period of time.
#    Please try again in a short while. "
#  infomation show to spamer
####################################################

sub _hdlr_easun_comment_filter {
        my ($eh, $app, $obj) = @_;
        # return 1 if (($obj->blog_id) != 1);
        my $q = $app->{query};
        my $sckey = &_get_SimpleCommentKey($obj->blog_id);
        return 1 if (!$sckey);
        my $inputkey = $q->param($sckey) or return 0;
        return ($inputkey eq &_get_SimpleCommentKeyValue($obj->blog_id)) ? 1 : 0;
}


sub _get_SimpleCommentKey
{
       my $blog_id = shift;
       return _get_encode_name($plugin->get_config_value('SimpleCommentKey', "blog:$blog_id"));
}

sub _get_SimpleCommentKeyValue
{
       my $blog_id = shift;
       return _get_encode_name($plugin->get_config_value('SimpleCommentKeyValue', "blog:$blog_id"));
}

sub _mt_tag_SimpleCommentJS
{
    my($ctx, $args) = @_;
    my $blog     = $ctx->stash('blog');
    my $blog_id  = $blog->id;
    my $key =  &_get_SimpleCommentKey($blog_id) ;
    my $out ;
    if ($key) {
      $out= 'f.'
            .$key
            .'.value = \''
            .&_get_SimpleCommentKeyValue($blog_id)
            .'\';';
            }
  scalar $out;
}

sub _mt_tag_SimpleCommentQueryString
{
    my($ctx, $args) = @_;
    my $blog     = $ctx->stash('blog');
    my $blog_id  = $blog->id;
    my $key =  &_get_SimpleCommentKey($blog_id) ;
    my $out ;
    if ($key) {
       $out= $key.'='.&_get_SimpleCommentKeyValue($blog_id);
       }
   scalar $out;
}

sub _mt_tag_SimpleCommentinFormKey
{
    my($ctx, $args) = @_;
    my $blog     = $ctx->stash('blog');
    my $blog_id  = $blog->id;
    my $key =  &_get_SimpleCommentKey($blog_id) ;
    my $out ;
    if ($key) {
    $out= '<input type="hidden" name="'
            .$key
            .'" value="1" />';
            }
   scalar $out;
}

sub _get_encode_name {
    my $str = shift;
    $str =~ s!([^a-zA-Z0-9_.~-])!lc sprintf "%02x", ord($1)!eg;
    #$str =~ s!(.)!lc sprintf "%02x", ord($1)!eg;
    $str;
}

sub _hdlr_easun_html_reduce {
        my ($str, $param, $ctx) = @_;
        $str =~ s/^\s+|\s+$//gs;
        $str =~ s!\s*\n\s*!\n!gs;
        $str =~ s!(\r|\t|\f| )+! !gs;
        $str;
}

## CommenterUserpicURL
sub _hdlr_gravatar_url {
        my ($url, $param, $ctx) = @_;  
        return $url if ($url ne '') ;   
           
        my $c = $ctx->stash('comment')
            or return $ctx->_no_comment_error();  
             
       #Easun 's QQ plugin    ($cmntr->auth_type =~ m/^QQ/ )  
       my $cmntr = $ctx->stash('commenter');
       if ($cmntr && $cmntr->hint && ($cmntr->hint=~ m!^https?://!) )  {  return $cmntr->hint; }
       
       if ($cmntr && $cmntr->url && ($cmntr->url =~ m/^QQ\|/ ) )  { 
           my $qqavatar = $cmntr->url;
           $qqavatar =~ s{^QQ\|}{}i;
           return $qqavatar ; 
       }   
         
       # gravatar_url         
       my $email = $c->email;
       return  'http://static.easunlee.cn/images/ds-avatar.png' if ($email eq '');
              
      require Digest::MD5;
             $url = "http://gravatar.duoshuo.com/avatar/".Digest::MD5::md5_hex(lc($email)).'?s=50&d=identicon';
            #$url .= exists $args->{size} ? "&amp;s=".$args->{size} : "";
            #$url .= exists $args->{rating} ? "&amp;r=".$args->{rating} : "";
            #$url .= exists $args->{default} ? "&amp;d=".uri_escape($args->{default}) : "";
            #$url .= exists $args->{border} ? "&amp;b=".$args->{border} : "";
        return $url;
}

1;
