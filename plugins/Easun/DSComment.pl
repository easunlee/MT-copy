package MT::Plugin::Easun::DSComment;

use strict;
use base 'MT::Plugin';
use MT::Template::Context;
use vars qw($VERSION);
$VERSION = '1.01';
our $str= 'info: ';
use MT;

my $plugin = MT::Plugin::Easun::DSComment->new(
             {
              name => '<MT_TRANS phrase="DSComment">',
              version => $VERSION,
              description => '<MT_TRANS phrase="A Simple plugin for Anti-Comment-SPAM plugin for Movable Type By Easun.org">',
              doc_link => 'http://easun.org/archives/mt_plugin/',
              author_name => '<MT_TRANS phrase="EasunLee">',
              author_link => 'http://easun.org/blog/',
              l10n_class => 'Easun::L10N',
              icon => 'easun.ico',
              blog_config_template => 'config_ds.tmpl',
              settings => new MT::PluginSettings([
                       [ 'DS_short_name', { Default => undef, scope => 'blog' } ],
                       [ 'DS_secret', { Default => undef, scope => 'blog' } ],
              ]),

              }
            );
MT->add_plugin($plugin);


sub init_registry {
    my $component = shift;
    my $reg = {
        'applications' => {
            'cms' => {
                'methods' => {
                    'ds_to_mt' => \&do_main_act,
                },
            },
        },
    };
    $component->registry($reg);
}

sub do_main_act
{
    	my $ctx = shift;
	my $args = shift;
	my $app = MT->instance;
	#return $app->error("HAHHAHAHHAHA"); 
	require JSON;
      # my $json = new JSON; #或以转换字符集
     my $json = JSON->new->utf8;
     my $json_obj = $json->decode( &get_ds_file_mt($app) );
     &check_ds_comments($app, $json_obj->{'response'});
}

sub check_ds_comments {
        my $app = shift ;     
        my $response = shift ;     
        my $list_ref;
        my $log_id;
        foreach my $a(@{$response} ) {
            my $act = $a->{'action'}; 
            if ( $act eq 'create') {   my $ds = $a->{'meta'};  my  $ds_id= $ds->{"post_id"};    $list_ref->{$ds_id} = $ds;  } 
           else
           {  
                   foreach my $var ( @{$a->{'meta'}} ) { $list_ref->{$var}->{'status'} = ($act eq 'approve') ? 'approved' : $act ;  }
            }
             $log_id = $a->{'log_id'};  
        }
        
        #my $str;
        my $nos = 0;        
        my @ids =sort {$a <=> $b} keys %$list_ref;        
        foreach my $ids ( @ids )
        {
           # print "<br>$ids:\n<br>";
           my $dscs = $list_ref->{$ids};
          $str .= "<br>\t$ids => $dscs->{'status'} \n<br>";
          next if ( ($dscs->{'status'} eq 'delete-forever') || ($dscs->{'status'} eq 'delete') || ($dscs->{'status'} eq 'spam'));
          next if  ($dscs->{"thread_key"}  !~ /^\d+$/);
          &import_comments($dscs);
          $nos ++;
       }                   
        $str .= "<p>信息：</p>"  ;
        $str .= "<br>last_log_id=" .$log_id;        
        $str .= "<br>共有有效评论 " .$nos ." 条。OK！！！！<br>";       
        return $app->error($str); 

}

sub import_comments {
	my $ds = shift ;
      require MT::Comment;    
      my @comments = MT::Comment->load( 
              { remote_service =>'DUOSHUO', remote_id=>$ds->{"post_id"},}, 
              { sort => 'created_on', direction => 'ascend',}          
          );
      my $comment =  $comments[0] ||  MT::Comment->new;
   
      #my $str ; 
      if ( $comment->id )
      {
         $str=  "<li>这个多说评论已经存在。 数据库中 id=". $comment->id ."</li>" ;
        # if ($comment->agent) { ; }
        # else { 
         	 $str .= '<li>没有检测到ds-agent, 更新....</li><li> ds->agent = '. $ds->{"agent"} .'</li>';
              $comment->agent($ds->{"agent"}) ;  
               $comment->save or die $comment->errstr; 
        #       }
          
         return; 
      }
      else {  $str .= "<li>没有检查到这个评论，准备写入...........</li>"; }
   
 #   $comment->blog_id($entry->blog_id);
 #   $comment->entry_id($entry->id);
 #   $comment->author('Foo');
 #   $comment->text('This is a comment.');


	# $comment->id($comment_id);  # \comment_  id# \,
	$comment->author($ds->{"author_name"} );# \comment_  author# \,
	$comment->blog_id(2); # \comment_  blog_id# \,
	$comment->commenter_id(1)  if ($ds->{'author_id'} =='11415448' ) ; # \comment_  commenter_id# \,
	#$comment->created_by('NULL,';  # \comment_  created_by# \,
	#$comment->created_on('"'. $ds->{"created_at"} ); # \comment_  created_on# \,
	$comment->email($ds->{"author_email"} );  # \comment_  email# \,
	$comment->entry_id( int($ds->{"thread_key"}) ); # \comment_  entry_id# \,
	$comment->ip( $ds->{"ip"} ); # \comment_  ip# \,
	#$comment->junk_log('NULL,';  # \comment_  junk_log# \,
	#$comment->junk_score('NULL,'; # \comment_  junk_score# \,
	#$comment->junk_status('1,';  # \comment_  junk_status# \,
	#$comment->last_moved_on("'2000-01-01 00:00:00',"; # \comment_  last_moved_on# \,
	#$comment->modified_by('NULL,'; # \comment_  modified_by# \,
	#$comment->modified_on('NULL,'; # \comment_  modified_on# \,
	$comment->parent_id( &get_id_form_ds_id( $ds->{"parent_id"} ) ); # \comment_  parent_id# \,
	$comment->text( $ds->{"message"} );  # \comment_  text# \,
	$comment->url( $ds->{"author_url"} );  # \comment_  url# \,
	$comment->visible(0) unless ($comment->id) ;  # \comment_  visible# \,   # 0 代表 等待发布。 1代表直接发布
	$comment->remote_id($ds->{"post_id"}); # \comment_  remote_id# \,
	$comment->remote_service('DUOSHUO' );  # \comment_  remote_service# \
	$comment->agent($ds->{"agent"}) ; # \comment_  agent# \,
       $comment->save
           or die $comment->errstr;
}


sub get_ds_file_mt
{
        my ( $app) = @_;
         my $secret = '';
         my $short_name = '';
         my $limit = '20';
         my $url = "http://api.duoshuo.com/log/list.json?short_name=${short_name}&secret=${secret}&limit=${limit}";
         my $ua = $app->new_ua( { paranoid => 1 } );         
         my $response = $ua->get($url);
         return $app->errtrans("Invalid request.-[_1]", "Get token not Success 1")
               unless $response->is_success;
         my $content = $response->content();
         $content; 
}

1;