package MT::Plugin::Easun::LightBox;
use strict; 
use 5.006; 
use warnings; 
use Data::Dumper;
use MT 4.0;
use base qw( MT::Plugin );
our($old);
{
    no warnings 'redefine';
    no strict 'refs';
    require MT::Asset::Image;
    if ($old = MT::Asset::Image->can('as_html')) {        
        *MT::Asset::Image::as_html = sub{
			 my ($texto) = $old->(@_);
			$texto =~ s/<a/<a data-lightbox="easun"/;
			return $texto;
		};     
    }
    
}

1;