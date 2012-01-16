# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

# string or file, not both
is eval { Text::VimColor->new( file => 'foo', string => 'bar') }, undef,
  "new() dies when given both 'string' and 'file'";
like $@, qr/only one of the 'file' or 'string' options/,
  "the 'string' and 'file' options should be mutually exclusive";

# neither (causes marked() to die)
my $syntax = Text::VimColor->new;
isa_ok($syntax, 'Text::VimColor');

is eval { $syntax->marked; 1 }, undef,
  'without a filename or string specified, marked() should die';
like $@, qr/an input file or string must be specified/,
  'error message states that intput is required';

# We should get a sensible error message if the named file isn't there.
is eval { Text::VimColor->new( file => 'file-that-does-not.exist' ) }, undef,
  'new dies when the specified file does not exist';
like($@, qr/input file '.*' not found/,
  "check we get the right error if the file doesn't exist");

# TODO: test other new() functionality

done_testing;
