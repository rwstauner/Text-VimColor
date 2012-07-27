use strict;
use warnings;
use Test::More;
use Text::VimColor;

# windows prints everything when STDIN is tied, don't know why
plan skip_all => "Skipped on windows"
  if $^O eq 'MSWin32';

# IPC::Open3 handles this now, but keep this as a regression test for rt-50646

my $tie = 'Tie::StdHandle';
plan skip_all => "$tie required for this test"
  unless eval "require $tie";

plan tests => 1;

tie *STDOUT, $tie;

my $marked = Text::VimColor->new(filetype => 'perl', string => "1\n")->marked;

is_deeply $marked, [[Constant => 1], ['', "\n"]], 'marked with tied handle';
