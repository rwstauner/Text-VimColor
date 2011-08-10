# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that we can deal with input files properly.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

plan tests => 1;

# We should get a sensible error message if the named file isn't there.
eval { Text::VimColor->new( file => 'some-random-non-existant-file.txt' ) };
like($@, qr/input file '.*' not found/,
     "check we get the right error if the file doesn't exist");
