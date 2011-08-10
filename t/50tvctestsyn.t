# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Test exact output against a syntax file we define.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

# clear out possible user customizations that could upset the tests
$ENV{TEXT_VIMCOLOR_ANSI} = '';

my @formats = qw(
   html
   xml
   ansi
);

plan tests => scalar @formats;

my $filetype = 'tvctestsyn';
my $syntax = Text::VimColor->new(
   filetype => $filetype,
);

foreach my $format (@formats) {
   my $input    = slurp_data("$filetype.txt");
   my $expected = slurp_data("$filetype.$format");

   $syntax->syntax_mark_string($input);
   is($syntax->$format, $expected, 'got expected marked text');
}
