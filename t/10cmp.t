# Check that things which should produce identical output do.

use strict;
use warnings;
use Test;
use Text::VimColor;
use Path::Class qw( file );

plan tests => 1;

# Check that passing coloring with the 'filetype' option has the same output
# whether Vim knows the filename or now.
my $filename = file('t', 'hello.c')->stringify;
my $syntax1 = Text::VimColor->new(
   file => $filename,
   filetype => 'c',
);
open my $file, '<', $filename or die "error opening file '$filename': $!";
my $text = do { local $/; <$file> };
my $syntax2 = Text::VimColor->new(
    string  => $text,
    filetype => 'c',
);
ok($syntax1->html eq $syntax2->html);

# Local Variables:
# mode: perl
# perl-indent-level: 3
# End:
# vim:ft=perl ts=3 sw=3 expandtab:
