use strict;
use warnings;
use Test::More;
use Text::VimColor;

my $tie = 'Tie::StdHandle';
plan skip_all => "$tie required for this test"
  unless eval "require $tie";

plan tests => 1;

tie *STDOUT, $tie;

my $marked = Text::VimColor->new(filetype => 'perl', string => "1\n")->marked;

is_deeply $marked, [[Constant => 1], ['', "\n"]], 'marked with tied handle';
