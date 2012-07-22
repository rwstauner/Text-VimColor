# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

eval { require Term::ANSIColor }
  or plan skip_all => 'Term::ANSIColor required for these tests';

no warnings 'redefine';
local *Term::ANSIColor::colored = sub {
  return sprintf '[%s]%s[]', $_[0]->[0], $_[1];
};

# clear out possible user customizations that could upset the tests
$ENV{TEXT_VIMCOLOR_ANSI} = '';

plan tests => 2;

my $filetype = 'tvctestsyn';
my $syntax = Text::VimColor->new(
  filetype => $filetype,
);

  my $input = "# Text::VimColor # (test)\n";

  $syntax->syntax_mark_string($input);
  is $syntax->ansi,
    tag_input(qw(Comment blue Special bright_magenta)),
    'default ansi colors';

  $ENV{TEXT_VIMCOLOR_ANSI} = 'Comment=green;Special = yellow; ';

  $syntax->syntax_mark_string($input);
  is $syntax->ansi,
    tag_input(qw(Comment green Special yellow)),
    'custom ansi colors from ENV';

sub tag_input {
  my %c = @_;
  if( Term::ANSIColor->VERSION < 3 ){
    s/bright_// for values %c;
  }
  return "[$c{Special}]#[] [cyan]Text[][$c{Special}]::[][cyan]VimColor[] " .
    "[$c{Special}]#[] [$c{Special}]([][$c{Comment}]test[][$c{Special}])[]\n";
}
