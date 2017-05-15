#
# Markdown -- A text-to-HTML conversion tool for web writers
#
# Copyright (c) 2004 John Gruber
# <http://daringfireball.net/projects/markdown/>
# Modify 2017 By EasunLee<https://easun.org>
# <https://github.com/easunlee/MT-copy/blob/master/plugins/Easun/Markdown_md.pl>
#

package MT::Plugin::Easun::Markdown;
use strict;
use warnings;

use vars qw($MYNAME $VERSION $DEBUG $Useproxy );
$VERSION = "1.03e";


#### Movable Type plug-in interface #####################################
use MT::Plugin;

my $plugin = new MT::Plugin(
    {   name        => "Markdown_Modify",
        author_name => "John Gruber",
        author_link => "http://daringfireball.net/",
        plugin_link => "http://daringfireball.net/projects/markdown/",
        version     => $VERSION,
        description =>
            '<MT_TRANS phrase="A plain-text-to-HTML formatting plugin.">',
        doc_link => 'http://daringfireball.net/projects/markdown/',
        registry => {
            tags => {
                block => {
                    MarkdownOptions => sub {
                        my $ctx     = shift;
                        my $args    = shift;
                        my $builder = $ctx->stash('builder');
                        my $tokens  = $ctx->stash('tokens');

                        if ( defined( $args->{'output'} ) ) {
                            $ctx->stash( 'markdown_output',
                                lc $args->{'output'} );
                        }

                        defined( my $str = $builder->build( $ctx, $tokens ) )
                            or return $ctx->error( $builder->errstr );
                        $str;    # return value
                    },
                },
            },
            text_filters => {
                'markdown' => {
                    label => 'Markdown_Modify',
                    docs  => 'http://daringfireball.net/projects/markdown/',
                    code  => sub {
                        my $text = shift;
                        my $ctx  = shift;
                        my $raw  = 0;
                        if ( defined $ctx ) {
                            my $output = $ctx->stash('markdown_output');
                            if ( defined $output && $output =~ m/^html/i ) {
                        #        $g_empty_element_suffix = ">";
                                $ctx->stash( 'markdown_output', '' );
                            }
                            elsif ( defined $output && $output eq 'raw' ) {
                                $raw = 1;
                                $ctx->stash( 'markdown_output', '' );
                            }
                            else {
                                $raw                    = 0;
                          #      $g_empty_element_suffix = " />";
                            }
                        }
                        $text = $raw ? $text : &_easunCode( $text );
                        $text;
                    },
                },
                

            },
        },
    }
);
MT->add_plugin($plugin);

sub _easunCode {
    my $text = shift;
      &_DoCodeBlocks_github(\$text);
          
    require Text::Markdown;
    my $m = Text::Markdown->new;    
    $text = $m->markdown($text);
    

    $text =~ s{<pre><code>```(.*?)\n}{<pre><b class=\"name\">$1<\/b><code class=\"language-$1\">}g; 
    $text =~ s/<pre><code>/<pre><b class=\"name\">code<\/b><code class=\"code\">/g;
    return $text;
}

#
#  GitHub style Code
#
sub _DoCodeBlocks_github {

    my $text = shift; 
    $$text =~ s{\r\n}{\n}g;    # DOS to Unix
    $$text =~ s{\r}{\n}g;      # Mac to Unix
    
 #    $$text =~ s{(\n\n|\A)(```\w+)\n}{$1\t$2\n}g;

    $$text =~ s{
               (?:\n\n|\A)
               ```(\w+)\n
            (               # $2 = the code block -- one or more lines, starting with a space/tab
                .*?
              )
               \n```
               (?:\n|\Z)
               }{
            my $codeType = $1;
            my $codeblock = $2;
            my $result; # return value
            

            $codeblock =~ s/\A\n+//; # trim leading newlines
            $codeblock =~ s/\s+\z//; # trim trailing whitespace  
            $codeblock =~ s/\n/\n\t/g;   

            $result = "\n\n\t```" .$codeType ."\n\t" . $codeblock . "\n\n";

            $result;
        }segmx;
        
}

1;

__END__


=pod

=head1 NAME

B<Markdown>


=head1 SYNOPSIS

B<Markdown.pl> [ B<--html4tags> ] [ B<--version> ] [ B<-shortversion> ]
    [ I<file> ... ]


=head1 DESCRIPTION

Markdown is a text-to-HTML filter; it translates an easy-to-read /
easy-to-write structured text format into HTML. Markdown's text format
is most similar to that of plain text email, and supports features such
as headers, *emphasis*, code blocks, blockquotes, and links.

Markdown's syntax is designed not as a generic markup language, but
specifically to serve as a front-end to (X)HTML. You can  use span-level
HTML tags anywhere in a Markdown document, and you can use block level
HTML tags (like <div> and <table> as well).

For more information about Markdown's syntax, see:

    http://daringfireball.net/projects/markdown/


=head1 OPTIONS

Use "--" to end switch parsing. For example, to open a file named "-z", use:

    Markdown.pl -- -z

=over 4


=item B<--html4tags>

Use HTML 4 style for empty element tags, e.g.:

    <br>

instead of Markdown's default XHTML style tags, e.g.:

    <br />


=item B<-v>, B<--version>

Display Markdown's version number and copyright information.


=item B<-s>, B<--shortversion>

Display the short-form version number.


=back



=head1 BUGS

To file bug reports or feature requests (other than topics listed in the
Caveats section above) please send email to:

    support@daringfireball.net

Please include with your report: (1) the example input; (2) the output
you expected; (3) the output Markdown actually produced.


=head1 VERSION HISTORY

See the readme file for detailed release notes for this version.

1.0.1 - 14 Dec 2004

1.0 - 28 Aug 2004


=head1 AUTHOR

    John Gruber
    http://daringfireball.net

    PHP port and other contributions by Michel Fortin
    http://michelf.com


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2004 John Gruber   
<http://daringfireball.net/>   
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution.

* Neither the name "Markdown" nor the names of its contributors may
  be used to endorse or promote products derived from this software
  without specific prior written permission.

This software is provided by the copyright holders and contributors "as
is" and any express or implied warranties, including, but not limited
to, the implied warranties of merchantability and fitness for a
particular purpose are disclaimed. In no event shall the copyright owner
or contributors be liable for any direct, indirect, incidental, special,
exemplary, or consequential damages (including, but not limited to,
procurement of substitute goods or services; loss of use, data, or
profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability, or tort (including
negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.

=cut
