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

$syntax->syntax_mark_string(slurp_data("$filetype.txt"));

is $syntax->$_, slurp_data("$filetype.$_"), "got expected marked text from $_"
  for @formats;
