# Check that the right things are being marked by the syntax highlighting
# for some test cases, and make sure we can get the results out as a Perl
# array of hashes.
#
# This also tests using a string as input rather than a file.

use strict;
use warnings;
use Test::More;
use Text::VimColor;

plan tests => 7 + 2 * 3;

# Making an object.
my $syntax = Text::VimColor->new;
is(ref $syntax, 'Text::VimColor',
   'new() should return Text::VimColor object');

# Without a filename or string specified, marked() should die.
eval { $syntax->marked };
ok($@ =~ /an input file or string must be specified/,
   'without a filename or string specified, marked() should die');
is($syntax->input_filename, undef,
   'without a filename or string specified, input_filename() should be undef');

# The 'string' and 'file' options should be mutually exclusive.
eval { Text::VimColor->new( file => 'foo', string => 'bar') };
ok($@ =~ /only one of the 'file' or 'string' options/,
   "the 'string' and 'file' options should be mutually exclusive");

# Test markup of some XML, and check format of Perl array output.
my $xml_input = "<element>text</element>\n";
my $xml_expected = [
   [ 'Identifier', '<element>' ],
   [ '', 'text' ],
   [ 'Identifier', '</element>' ],
   [ '', "\n" ],
];
$syntax = Text::VimColor->new(filetype => 'xml');
my $xml_marked1 = $syntax->syntax_mark_string($xml_input)->marked;
$syntax = Text::VimColor->new(string => $xml_input, filetype => 'xml');
my $xml_marked2 = $syntax->marked;
ok(syncheck($xml_expected, $xml_marked1),
   'markup works with string input to syntax_mark_string()');
ok(syncheck($xml_expected, $xml_marked2),
   'markup works using string input and marked()');

# Check filename when input was a string.
is($syntax->input_filename, undef,
   'when input is a string, input_filename() should be undef');


# Runs 3 tests through the testing infrastructure.
sub syncheck
{
   my ($expected, $marked) = @_;

   isnt($marked, undef,
      "syntax markup shouldn't be undef");
   is(ref $marked, 'ARRAY',
      "syntax markup should be an array ref");
   is(@$marked, @$expected,
      "syntax markup should have the expected number of elements");

   for my $i (0 .. $#$expected) {
      my $e = $expected->[$i];
      my $m = $marked->[$i];
      unless (defined $m) {
         diag "element $i not defined";
         return;
      }
      unless (ref $m eq 'ARRAY') {
         diag "element $i not an array ref";
         return;
      }
      unless (@$m == 2) {
         diag "element $i has size " . scalar(@$m) . ", not two";
         return;
      }
      unless ($m->[0] eq $e->[0]) {
         diag "element $i has type '$m->[0]', not '$e->[0]'";
         return;
      }
      unless ($m->[1] eq $e->[1]) {
         diag "element $i has text '$m->[0]', not '$e->[0]'";
         return;
      }
   }

   return 1;
}

# vim:ft=perl ts=3 sw=3 expandtab:
