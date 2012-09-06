# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

my @defaults = @Text::VimColor::VIM_OPTIONS;

# sanity check
test_expected_options();

is_deeply
  [ tvc(vim_options => [text => vim => 'color'])->vim_options ],
  [qw(text vim color)],
  'overwrite vim_options';

is_deeply
  [ tvc(vim_options => [@defaults, '+set fenc=utf-8'])->vim_options ],
  [@defaults, '+set fenc=utf-8'],
  'overwrite vim_options with defaults plus one extra';

is_deeply
  [ tvc(extra_vim_options => ['+set fenc=utf-8'])->vim_options ],
  [@defaults, '+set fenc=utf-8'],
  'use extra_vim_options to get the same effect';

{
  local @Text::VimColor::VIM_OPTIONS = qw(local vim options);
  is_deeply
    [ tvc()->vim_options ],
    [qw(local vim options)],
    'use localized @Text::VimColor::VIM_OPTIONS for backward compatibility';

  is_deeply
    [ tvc(extra_vim_options => ['foo'])->vim_options ],
    [qw(local vim options foo)],
    'use localized @Text::VimColor::VIM_OPTIONS for backward compatibility';
}

# after all that the defaults are still the defaults:
is_deeply
  [ tvc()->vim_options ],
  [@defaults],
  'default vim_options';

is_deeply
  [ tvc(extra_vim_options => ['bar'])->vim_options ],
  [@defaults, 'bar'],
  'default vim_options plus extra_vim_options';

# make sure nothing has altered them
test_expected_options();

done_testing;

# these values could theoretically change, but they probably won't
sub test_expected_options {
  is_deeply
    [ @defaults[1..4] ],
    [-i => 'NONE', -u => 'NONE'],
    'default vim options disable .vimrc and .viminfo';

  ok scalar grep { /\+set nomodeline/ } @defaults, 'nomodeline set in default vim options';
}
