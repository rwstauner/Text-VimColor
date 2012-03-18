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

my $filetype = 'tvctestsyn';
my $syntax = Text::VimColor->new(
  filetype => $filetype,
);

$syntax->syntax_mark_string(slurp_data("$filetype.txt"));

my %data = map { ($_ => slurp_data("$filetype.$_")) } @formats;
# NOTE: this hack is very specific and very fragile
require Term::ANSIColor;
$data{ansi} =~ s/\e\[95m/\e\[35m/g if Term::ANSIColor->VERSION < 3;

is $syntax->$_, $data{$_}, "got expected marked text from $_"
  for @formats;

is_deeply
  $syntax->marked,
  [
    [ 'Special',     "#" ],
    [ '',            " " ],
    [ 'Identifier',  "Text" ],
    [ 'Special',     "::" ],
    [ 'Identifier',  "VimColor" ],
    [ '',            " test file " ],
    [ 'Special',     "#" ],
    [ '',            "\n\nMarked with " ],
    [ 'Constant',    "t/.vim/syntax/tvctestsyn.vim" ],
    [ '',            "\nthis file is used for reliably testing syntax marking\n" ],
    [ 'Special',     "(" ],
    [ 'Comment',     "rather than relying on an external " ],
    [ 'Todo',        "vim" ],
    [ 'Comment',     " file " ],
    [ 'Type',        "that" ],
    [ 'Comment',     " may change" ],
    [ 'Special',     ")" ],
    [ '',            ".\n                                    \\/\n" ],
    [ 'Special',     "(" ],
    [ 'Type',        "this" ],
    [ 'Comment',     " line ends with whitespace " ],
    [ 'Statement',   "->" ],
    [ 'Special',     ")" ],
    [ '',            "  \n                                    /\\\n\n" ],
    [ 'Special',     "(" ],
    [ 'Comment',     " " ],
    [ 'Todo',        "vim" ],
    [ 'Comment',     ": set ft=tvctestsyn : " ],
    [ 'Special',     ")" ],
    [ '',            "\n" ],
  ],
  'got expected arrayref structure for tvctestsyn';

done_testing;
