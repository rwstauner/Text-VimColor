# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that things which should produce identical output do.

use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use TVC_Test;

# test vars set via new() or vim_let()
{
  my %let = %Text::VimColor::VIM_LET;

  ok scalar keys %let, 'there are some default vars';

  is_deeply tvc()->{vim_let}, \%let, 'default vim_let vars';

  my %extras = (foo => 'bar', baz => 'qux');

  is_deeply
    tvc(vim_let => { %extras })->{vim_let},
    { %let, %extras },
    'additional vim_let vars';

  is_deeply tvc(vim_let => {})->{vim_let}, \%let, 'no additional vim_let vars';

  my $tvc = tvc();
  $tvc->vim_let(%extras);

  is_deeply
    $tvc->{vim_let},
    { %let, %extras },
    'additional vim_let vars added via method';
}

# TODO: get the vim command args and verify that vim_let(foo => undef) excludes foo

SKIP: {

# test the actual effects of different vim_let vars
# (using shell vs bash as an example)

# Text::VimColor historically set b:is_bash.
# We'll test that functionality with our custom syntax for portability.

my $input            = "# vim\nisbash\n";
my ($expected_bash_output, $expected_sh_output) =
  map {
    qq[<syn:syntax xmlns:syn="http://ns.laxan.com/text-vimcolor/1">] .
    qq[<syn:Special>#</syn:Special> <syn:Todo>vim</syn:Todo>\n$_\n</syn:syntax>\n]
  }
    'isbash',
    '<syn:Error>isbash</syn:Error>';

foreach my $test (
  [$expected_bash_output, undef,
    'by default shell should enable bash features'],
  [$expected_sh_output,   { 'b:is_bash' => undef },
    'shell should disable bash features with b:is_bash=undef'],
  [$expected_sh_output,   { foo => '"bar"', 'b:is_bash' => undef },
    'disable bash features with { foo => "bar", b:is_bash => undef }'],
  [$expected_bash_output, { 'b:is_bash' => 1 },
    'shell should enable bash features with b:is_bash=1'],
){
  my ($exp, $let, $desc) = @$test;
  my $filetype = 'tvctestsyn';

  # First test setting 'let' values in the constructor.
  {
    my $syntax = Text::VimColor->new(
      string   => $input,
      filetype => $filetype,
      ( $let ? (vim_let => $let) : ()),
    );
    is $syntax->xml, $exp, "$desc via new()";
  }

  # now test setting 'let' values with the 'vim_let' method.
  {
    my $syntax = Text::VimColor->new;
    $syntax->vim_let(%$let) if $let;
    $syntax->syntax_mark_string($input, filetype => $filetype);
    is $syntax->xml, $exp, "$desc via vim_let()";
  }
}

} # skip (vim < 6.3)

done_testing;
