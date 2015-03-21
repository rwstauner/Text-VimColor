# Test that additional syntax groups get activated with all_syntax_groups => 1

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

sub marked {
  return Text::VimColor->new(
    string   => '#include <stdio.h>',
    filetype => 'c',
    @_
  )->marked;
}

sub first_syntax_group {
  marked(@_)->[0][0];
}

is first_syntax_group(),
  'PreProc',
  'linked to default group';

is first_syntax_group(all_syntax_groups => 1),
  'Include',
  'more specific group is used with all_syntax_groups enabled';

is ansi_color('String'), ansi_color('Constant'),
  'String is linked to Constant';

ok syntax_type_exists('Function'),
  'Function syntax type declared';

{
  # regression test
  ok !syntax_type_exists('red'),
    'ansi color not copied to syntax type';
}

done_testing;
