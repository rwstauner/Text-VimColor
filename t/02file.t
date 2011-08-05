# Check that we can deal with input files properly.

use strict;
use warnings;
use Test::More;
use Text::VimColor;
require "t/lib/test_env.pm";

plan tests => 1;

# We should get a sensible error message if the named file isn't there.
eval { Text::VimColor->new( file => 'some-random-non-existant-file.txt' ) };
like($@, qr/input file '.*' not found/,
     "check we get the right error if the file doesn't exist");

# vim:ft=perl ts=3 sw=3 expandtab:
