# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that things which should produce identical output do.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

plan tests => 2 * 4;

# Check that passing coloring with the 'filetype' option has the same output
# whether Vim knows the filename or not.
my $filename = file('t', 'data', 'hello.c')->stringify;
my $syntax1 = Text::VimColor->new(
  file => $filename,
  filetype => 'c',
);
open my $file, '<', $filename or die "error opening file '$filename': $!";
my $text = do { local $/; <$file> };

my $syntax2 = Text::VimColor->new(
  string  => $text,
  filetype => 'c',
);
compare(file => $syntax1, 'string' => $syntax2);

# Same again, but this time use a reference to a string.
my $syntax3 = Text::VimColor->new(
  string  => \$text,
  filetype => 'c',
);
compare(file => $syntax1, 'reference to a string' => $syntax3);

sub compare {
  my ($t1, $s1, $t2, $s2) = @_;

  my $desc = "output for hello.c is the same from $t1 and $t2";
  is($s1->html, $s2->html, "HTML $desc");
  is(xml_minus_filename($s1->xml),  $s2->xml, "XML $desc");
  is($s1->ansi, $s2->ansi, "ANSI $desc");
  is_deeply($s1->marked, $s2->marked, "Array reference $desc");
}
