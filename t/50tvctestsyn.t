# Test exact output against a syntax file we define.

use strict;
use warnings;
use Test::More;
use Text::VimColor;
use Path::Class qw( file );
require "t/lib/test_env.pm";

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
   my $input = load_file("$filetype.txt");
   my $expected = load_file("$filetype.$format");

   $syntax->syntax_mark_string($input);
   is($syntax->$format, $expected, 'got expected marked text');
}

sub load_file
{
   my ($filename) = @_;
   $filename = file('t', 'data', $filename)->stringify;
   open my $file, '<', $filename
      or die "error opening file '$filename': $!";

   return do { local $/; <$file> };
}

# vim:ft=perl ts=3 sw=3 expandtab:
