#------------------------------------------------------------------
#	Copyright (c) 2006, Lee, Joon (http://alogblog.com/)
#	This code is released under a Creative Commons License.
#		(http://creativecommons.org/licenses/by-nc-sa/2.5/)
#------------------------------------------------------------------
#	Below subroutines are converted by Lee, Joon(alogblog.com)
#	from ANTI-SPAM EMAIL LINK OBFUSCATOR which is a javascript
#	on http://www.jottings.com/obfuscator/
#	This tool was originally conceived and written by Tim Williams
#	of The University of Arizona. The code to randomly generate
#	a different encryption key each time the tool is used was
#	written by Andrew Moulden of Site Engineering Ltd.
#------------------------------------------------------------------
package Easun::Obfuscator;

use strict;
use POSIX;

my $rnd_seed_c = time;

sub rnd_c {
	$rnd_seed_c = ($rnd_seed_c*9301+49297) % 233280;
	$rnd_seed_c / (233280.0);
}

sub _rand_c {
	my $number = shift;
	ceil(rnd_c() * $number);
}

sub munge {
	my $js_file = shift;
	my $address = lc shift;
	my $mode = shift;
	my $path = shift;
	my $hidden = shift;

	my $coded = '';
	my $unmixedkey = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
	my $inprogresskey = $unmixedkey;
	my $mixedkey = '';
	my $unshuffled = 62;
	my $chr;

	for(my $i = 0; $i <= 62; $i++) {
		my $ranpos = _rand_c($unshuffled) - 1;
		my $nextchar = substr($inprogresskey, $ranpos, 1);
		$mixedkey .= $nextchar;
		my $before = substr($inprogresskey, 0, $ranpos);
		my $after = substr($inprogresskey, $ranpos+1, $unshuffled);
		$inprogresskey = $before.$after;
		$unshuffled -= 1;
	}
	my $cipher = $mixedkey;

	my $shifts = length $address;

	for(my $j=0; $j<length $address; $j++) {
		if(index($cipher, substr($address, $j, 1)) == -1) {
			$chr = substr $address, $j, 1;
			$coded .= substr $address, $j, 1;
		}
		else {
			$chr = (index($cipher, substr($address, $j, 1)) + $shifts) % (length $cipher);
			$coded .= substr $cipher, $chr, 1;
		}
	}

	if($js_file) {
		return "<script type=\"text/javascript\" src=\"$js_file\"></script><script type=\"text/javascript\">obfuscator('$coded', '$cipher', '$mode', '$path', '$hidden');</script>";
	} else {
		return "<script type=\"text/javascript\">obfuscator('$coded', '$cipher', '$mode', '$path', '$hidden');</script>";	
	}
}
