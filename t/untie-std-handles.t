use strict;
use warnings;
use Test::More;
use Text::VimColor;

my $tie = 'Tie::StdHandle';
plan skip_all => "$tie required for this test"
  unless eval "require $tie";

plan tests => 1;

tie *STDIN,  $tie;
tie *STDOUT, $tie;
tie *STDERR, $tie;

# TODO: is there any way to capture warnings in the forked child and be able
# to compare them here?  push @warnings, $_[0] won't affect the parent

is_deeply(
  Text::VimColor->new(filetype => 'perl', string => "1\n")->marked,
  [[Constant => 1], ['', "\n"]],
  'marked'
);
