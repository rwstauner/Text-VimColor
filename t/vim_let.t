# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that things which should produce identical output do.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

# If the version of Vim is too old to do the right shell-script highlighting,
# then just don't bother.
{
  open my $vim, '-|', 'vim --version'
    or die "error running 'vim --version': $!";
  my $line = <$vim>;
  die "couldn't read version from 'vim --version'"
    unless defined $line;
  if ($line =~ / (\d+)\.(\d+) / && ($1 >= 7 || ($1 == 6 && $2 >= 3))) {
    plan tests => 8;
  }
  else {
    plan skip_all => 'need Vim 6.3 for this to work';
  }
}

my $input                = slurp_data('shell.sh');
my $expected_sh_output   = slurp_data('shell-sh.xml');
my $expected_bash_output = slurp_data('shell-bash.xml');

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

  # First test setting 'let' values in the constructor.
  {
    my $syntax = Text::VimColor->new(
      string   => $input,
      filetype => 'sh',
      ( $let ? (vim_let => $let) : ()),
    );
    is $syntax->xml, $exp, "$desc via new()";
  }

  # now test setting 'let' values with the 'vim_let' method.
  {
    my $syntax = Text::VimColor->new;
    $syntax->vim_let(%$let) if $let;
    $syntax->syntax_mark_string($input, filetype => 'sh');
    is $syntax->xml, $exp, "$desc via vim_let()";
  }
}
