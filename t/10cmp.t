# Check that things which should produce identical output do.

use strict;
use warnings;
use Test::More;
use Text::VimColor;
use Path::Class qw( file );

plan tests => 2;

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
is($syntax1->html, $syntax2->html,
   'check that HTML output for hello.c comes out right');

# Same again, but this time use a reference to a string.
my $syntax3 = Text::VimColor->new(
   string  => \$text,
   filetype => 'c',
);
is($syntax1->html, $syntax3->html,
   'check that HTML output for hello.c comes out right using a string ref');

# vim:ft=perl ts=3 sw=3 expandtab:
