# Check that the right things are being marked by the syntax highlighting
# for some test cases, and make sure we can get the results out as a Perl
# array of hashes.
#
# This also tests using a string as input rather than a file.

use strict;
use warnings;
use Test;
use Text::VimColor;

plan tests => 7;

# Use the Vim script, etc., that are in the distro.
$Text::VimColor::SHARED = 'shared';

# Test 1: making an object.
my $syntax = Text::VimColor->new;
ok(ref $syntax eq 'Text::VimColor');

# Tests 2-3: without a filename or string specified, marked() should die.
eval { $syntax->marked };
ok($@ =~ /an input file or string must be specified/);
ok(!defined $syntax->input_filename);

# Test 4: the 'string' and 'file' options should be mutually exclusive.
eval { Text::VimColor->new( file => 'foo', string => 'bar') };
ok($@ =~ /only one of the 'file' or 'string' options/);

# Tests 5-6: test markup of some XML, and check format of Perl array output.
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
ok(syncheck($xml_expected, $xml_marked1));
ok(syncheck($xml_expected, $xml_marked2));

# Test 7: check filename when input was a string.
ok(!defined $syntax->input_filename);


sub syncheck
{
   my ($expected, $marked) = @_;

   unless (defined $marked) {
      warn "syntax markup undefined";
      return;
   }
   unless (ref $marked eq 'ARRAY') {
      warn "syntax markup not an array ref";
      return;
   }

   unless (@$expected == @$marked) {
      warn "syntax markup has not the expected number of elements";
      return;
   }

   for my $i (0 .. $#$expected) {
      my $e = $expected->[$i];
      my $m = $marked->[$i];
      unless (defined $m) {
         warn "element $i not defined";
         return;
      }
      unless (ref $m eq 'ARRAY') {
         warn "element $i not an array ref";
         return;
      }
      unless (@$m == 2) {
         warn "element $i has size " . scalar(@$m) . ", not two";
         return;
      }
      unless ($m->[0] eq $e->[0]) {
         warn "element $i has type '$m->[0]', not '$e->[0]'";
         return;
      }
      unless ($m->[1] eq $e->[1]) {
         warn "element $i has text '$m->[0]', not '$e->[0]'";
         return;
      }
   }

   return 1;
}

# Local Variables:
# mode: perl
# perl-indent-level: 3
# End:
# vim:ft=perl ts=3 sw=3 expandtab:
