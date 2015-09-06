# Acronym - Adds acronym tags to known acronyms.
# "This is a XHTML test" becomes "This is a <acronym title="Extensible HyperText Markup Language">XHTML</acronym> test"
# Henrik Gemal - http://gemal.dk/mt/acronym.html
# If you modify this code please let me know and I'll try to incorporate the changes into Acronym

package MTPlugins::Acronym;

use strict;
use warnings;
use MT;
use MT::Template::Context;
use MT::ConfigMgr;
use SelfLoader;

use vars qw($VERSION $DEBUG);
$VERSION = "2.1";
$DEBUG = 0;

if (MT->version_number >= 3) {
        use MT::Plugin;
        my $plugin = new MT::Plugin();
        $plugin->name("Acronym");
        # $plugin->config_link("../mt-acronym.cgi?__mode=mnu");
        $plugin->description("Adds acronym tags to known acronyms. Version $VERSION");
        $plugin->doc_link("http://gemal.dk/mt/acronym.html");
        MT->add_plugin($plugin);
}

MT::Template::Context->add_global_filter(acronym => \&acronym_subst);

1;

__DATA__

sub acronym_debug {
        my($txt) = @_;
        print STDERR "MTAcronym: $txt\n" if ($DEBUG);
}

sub acronym_load {
        my $file = shift;
        if (my $acronym_plugin = MT::ConfigMgr->instance->PluginPath) {
                $acronym_plugin .= "/$file";
                acronym_debug("Loading <$acronym_plugin>");
                open(FILE, $acronym_plugin) or die "Cannot open file <$acronym_plugin> ($!)";
                my %ACRONYM = map { chomp; (split /:/) } <FILE>;
                close FILE;
                return %ACRONYM;
        } else {
                acronym_debug("Unable to get PluginPath");
        }
}

sub acronym_subst {
        my ($str, $param, $ctx) = @_;

        my %ACRONYM = acronym_load("Easun/acronym.db");
        my $tokens = _tokenize($str);

        my $acronym_subst_out = "";
        my $acronym_subst_intag = 0;
        my $acronym_subst_changed = 0;

        my $acronym_tags = "(a|embed|object|acronym|abbr|dfn|code|math)";
        my $acronym_text_start = '(\s|^|,|\.|\(|\/|-|:)';
        my $acronym_text_end = '(\s|$|,|\.|\)|\/|-|:|\'|\?|\!)';

        foreach my $token (@$tokens) {
                if ($token->[0] eq 'tag') {
                        if ($token->[1] =~ /<$acronym_tags[^>]*>/) {
                                $acronym_subst_intag = 1;
                        } elsif ($token->[1] =~ /<\/$acronym_tags>/) {
                                $acronym_subst_intag = 0;
                        }
                } else {
                        if (!$acronym_subst_intag) {
                                if ($token->[1] =~ /$acronym_text_start([A-Z0-9]+)$acronym_text_end/) {
                                        foreach my $key (keys %ACRONYM) {
                                                my $s = $ACRONYM{$key};
                                                if ($token->[1] =~ s/$acronym_text_start$key$acronym_text_end/$1<acronym title=\"$s\">$key<\/acronym>$2/g) {
                                                        $acronym_subst_changed = 1;
                                                }
                                        }
                                }
                        }
                }
                $acronym_subst_out .= $token->[1];
        }
        if ($acronym_subst_changed) {
                return $acronym_subst_out;
        } else {
                return $str;
        }
}

sub _tokenize {
        my ($str) = @_;
        my $pos = 0;
        my $len = length $str;
        my @tokens;
        while ($str =~ m!(<([^>]+)>)!gs) {
                my ($whole_tag, $tag) = ($1, $2);
                my $sec_start = pos $str;
                my $tag_start = $sec_start - length $whole_tag;
                push @tokens, ['text', substr ($str, $pos, $tag_start - $pos)]
                        if $pos < $tag_start;
                push @tokens, ['tag', $whole_tag];
                $pos = pos $str;
        }
        push @tokens, ['text', substr ($str, $pos, $len - $pos)] if $pos < $len;
        \@tokens;
}

__END__
