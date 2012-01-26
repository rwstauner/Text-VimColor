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

# test default and custom options
foreach my $test (
  [vim_command              => 'vim', '/specific/vim'],
  # vim_options has it's own script
  [html_inline_stylesheet   => 1, 0],
  [xml_root_element         => 1, 0],
  # vim_let has it's own script
){
  my ($name, $default, $override) = @$test;
  # don't look, we're breaking encapsulation
  is tvc(                  )->{ $name }, $default,  "default $name";
  is tvc($name => $override)->{ $name }, $override, "override $name";
}

done_testing;
