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
       if ($cmntr && $cmntr->hint && ($cmntr->hint=~ m!^https?://!) )  { return $cmntr->hint; }
         
       # gravatar_url         
       my $email = $c->email;
       return  'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=' if ($email eq '');       
              
      require Digest::MD5;
      my $md5_mail = Digest::MD5::md5_hex(lc($email)) ;
      
      my $local_path = File::Spec->catdir( MT->instance->support_directory_path, 'avatar' );
      $local_path =~ s|/$||  unless $local_path eq  '/';  ## OS X doesn't like / at the end in mkdir().
      my $cache_file_main =  File::Spec->catfile( $local_path, $md5_mail);
      my $cache_dir_url = MT->instance->support_directory_url .'avatar/' ;
      
      my $ext ='.png'; #先设置后缀为 png,因为检查机制不知道图像类型。
      
      require MT::FileMgr;
      my $fmgr     = MT::FileMgr->new('Local'); 
      
#      unless ( $fmgr->exists($cache_file_main. $ext) )  #没有 .png
#      { 
#          $ext = '.gif' ;  #检查 .gif 
#          unless ( $fmgr->exists($cache_file_main. $ext) ) { $ext = '.jpg' ;}    #设定为 .jpg  
#      }
#      
      my $cache_file = $cache_file_main . $ext ;      
      my $cache_file_url= $cache_dir_url . $md5_mail . $ext ; 
      
      if ( $fmgr->exists($cache_file) ) {                
        my $mtime    = $fmgr->file_mod_time( $cache_file );
        my $INTERVAL = 60 * 60 * 24 * 7;
        if ( $mtime > time - $INTERVAL ) {
            # newer than 7 days ago, don't download the userpic
            return $cache_file_url;
        }
        $fmgr->delete($cache_file);  #超过7天啦。删除。
      }
    return &_get_from_gravatar_noassetset( $md5_mail, $local_path,$cache_dir_url);

}

sub _get_from_gravatar_noassetset { 
    my ($md5,$local_path,$cache_dir_url) = @_;
    my $image_url = "http://cn.gravatar.com/avatar/" . $md5 . '?s=50&d=identicon' ;
    my $ua = MT->new_ua( { paranoid => 1 } )  or return;
    my $resp = $ua->get($image_url);
    return $image_url unless $resp->is_success;
    return $image_url if $resp->code eq '404';
    my $image = $resp->content;
    return $image_url unless $image;
    my $mimetype = $resp->header('Content-Type');
    return $image_url unless $mimetype;
#    my $ext = {
#        'image/jpeg' => '.jpg',
#        'image/png'  => '.png',
#        'image/gif'  => '.gif'
#    }->{$mimetype};
#    
#    unless ($ext) { $ext ='.png'; } #如果没有获取到 mimetype 强行设置为 png 
      my $ext ='.png';   # 强行设置为 png 

    require MT::FileMgr;
    my $fmgr = MT::FileMgr->new('Local');
    
    unless ( $fmgr->exists($local_path) ) { $fmgr->mkpath($local_path); }
    my $local_img   = File::Spec->catfile( $local_path, $md5 . $ext );
    $fmgr->put_data( $image, $local_img, 'upload' );
    return $cache_dir_url . $md5 . $ext  ;
}

1;
