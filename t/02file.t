# Check that we can deal with input files properly.

use strict;
use warnings;
use Test;
use Text::VimColor;

plan tests => 1;

# Test 1: we should get a sensible error message if the named file isn't there.
eval { Text::VimColor->new( file => 'some-random-non-existant-file.txt' ) };
ok($@ =~ /input file '.*' not found/);


# Local Variables:
# mode: perl
# perl-indent-level: 3
# End:
# vim:ft=perl ts=3 sw=3 expandtab:
