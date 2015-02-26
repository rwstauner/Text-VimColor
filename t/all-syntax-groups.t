# Test that additional syntax groups get activated with all_syntax_groups => 1

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

plan tests => 2;

my $linked = Text::VimColor->new(
    string   => "()",
    filetype => 'vim',
)->marked;

my $unlinked = Text::VimColor->new(
    all_syntax_groups => 1,
    string            => "()",
    filetype          => 'vim',
)->marked;

is($linked->[0][0], 'Special', 'The Delimiter group is linked to Special by default');
is($unlinked->[0][0], 'Delimiter', 'The Delimiter group is used if it has its own coloring');
