# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that the XML output is correct.
# Also checks that tabs aren't tampered with.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;
use IO::File;
use Path::Class qw( file );

my $NS = 'http://ns.laxan.com/text-vimcolor/1';
my %SYNTYPES = map { $_ => 1 } qw(
   Comment Constant Identifier Statement Preproc
   Type Special Underlined Error Todo
);

my @EXPECTED_PERL_SYN = qw(
   Comment
   Statement Identifier
   Statement Constant Statement
   Statement Constant Identifier Constant
   Constant Special Constant
);
# vim will guess that string input is 'conf'
my @EXPECTED_NOFT_SYN = qw(
   Comment
   Constant
   Constant
);

eval " use XML::Parser ";
if ($@) {
   plan skip_all => 'XML::Parser module required for these tests.';
   exit 0;
}
else {
   plan tests => 12;
}

# Syntax color a Perl program, and check the XML output for well-formedness
# and validity.  The tests are run with and without a root element in the
# output, and with both filename and string as input.
my $filename = file(qw( t data has_tabs.pl ))->stringify;
my $file = IO::File->new($filename, 'r')
   or die "error opening file '$filename': $!";
my $data = do { local $/; <$file> };

# The value of these tests is not vim's filetype detection, so set it
# explicitly for portability across vim versions - rwstauner 2012-03-17
my $syntax = Text::VimColor->new(
   file => $filename,
   filetype => 'perl',
);
my $syntax_noroot = Text::VimColor->new(
   file => $filename, xml_root_element => 0,
   filetype => 'perl',
);
my $syntax_str = Text::VimColor->new(
   string => $data,
   filetype => 'conf',
);
my $syntax_str_noroot = Text::VimColor->new(
   string => $data, xml_root_element => 0,
   filetype => 'conf',
);

my %syntax = (
   'no root element, filename input' => $syntax_noroot,
   'no root element, string input' => $syntax_str_noroot,
   'root element, filename input' => $syntax,
   'root element, string input' => $syntax_str,
);

# These are filled in by the handler subs below.
my $text;
my $root_elem_count;
my $inside_element;
my @syntax_types;

my $parser = XML::Parser->new(
   Handlers => {
      Start => \&handle_start,
      End => \&handle_end,
      Char => \&handle_text,
      Default => \&handle_default,
   },
);

foreach my $test_type (sort keys %syntax) {
   #diag("Doing XML tests for configuration '$test_type'.");
   my $syn = $syntax{$test_type};
   my $xml = $syn->xml;

   # The ones without root elements need to be faked.
   if ($test_type =~ /no root/) {
      $xml = "<syn:syntax xmlns:syn='$NS'>$xml</syn:syntax>";
   }

   # Reset globals.
   # These get modified by the Handler subs in the next call to $parser->parse.
   $text = '';
   $root_elem_count = 0;
   $inside_element = 0;
   @syntax_types = ();

   $parser->parse($xml);

   is($text, $data,
      "check that text from XML output matches original");
   is($root_elem_count, 1,
      "there should only be one root element");

  my $expected = ($test_type =~ /string/)
    # Only expected to find string literals and comments.
    ? \@EXPECTED_NOFT_SYN
    : \@EXPECTED_PERL_SYN;

  is_deeply($expected, \@syntax_types,
    "syntax types marked in the right order for '$test_type'")
      or diag explain { exp => $expected, got => \@syntax_types };
}


sub handle_text
{
   my ($expat, $s) = @_;
   $text .= $s;
}

sub handle_start
{
   my ($expat, $element, %attr) = @_;
   $element =~ /^syn:(.*)\z/
      or fail("element <$element> has wrong prefix"), return;
   $element = $1;

   fail("element <syn:$element> shouldn't be nested in something")
      if $inside_element;

   if ($element eq 'syntax') {
      ++$root_elem_count;
      fail("namespace declaration missing from root element")
         unless $attr{'xmlns:syn'};
      fail("wrong namespace declaration in root element")
         unless $attr{'xmlns:syn'} eq $NS;
   }
   else {
      $inside_element = 1;
      fail("bad element <syn:$element>")
         if !$SYNTYPES{$element};
      fail("element <syn:$element> shouldn't have any attributes")
         if keys %attr;

      # HACK: ignore more than a single line of comments at the beginning
      # of the file (which might be added dynamically during build).
      # can be removed if this gets merged (or we stop using Prepender):
      # https://github.com/jquelin/dist-zilla-plugin-prepender/pull/1
      return if @syntax_types == 1 && $element eq 'Comment';

      push @syntax_types, $element;
   }
}

sub handle_end
{
   my ($expat, $element) = @_;
   $element =~ /^syn:(.*)\z/
      or fail("element <$element> has wrong prefix"), return;
   $element = $1;

   $inside_element = 0;

   if ($element ne 'syntax' && !$SYNTYPES{$element}) {
      fail("bad element <syn:$element>");
      return;
   }
}

sub handle_default
{
   my ($expat, $s) = @_;
   return unless $s =~ /\S/;
   die "unexpected XML event for text '$s'\n";
}
