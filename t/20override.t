# Test that options in calls syntax_mark_file() and syntax_mark_string()
# override the ones passed to new().

use strict;
use warnings;
use Test::More;
use Text::VimColor;
use Path::Class qw( file );

plan tests => 4;

my $syntax = Text::VimColor->new(
   filetype => 'perl',
);

my $input_filename = file('t', 'table.sql')->stringify;
my $input = load_file('table.sql');
my $expected_sql = load_file('table.sql.xml');
my $expected_borked = load_file('table.borked.xml');

$syntax->syntax_mark_file($input_filename, filetype => 'sql');
my $output = $syntax->xml;
$output =~ s/ filename=".*?"//;
is($output, $expected_sql, 'syntax_mark_file options override defaults');

$syntax->syntax_mark_file($input_filename);
$output = $syntax->xml;
$output =~ s/ filename=".*?"//;
is($output, $expected_borked, 'syntax_mark_file goes back to defaults');

$syntax->syntax_mark_string($input, filetype => 'sql');
is($syntax->xml, $expected_sql, 'syntax_mark_string options override defaults');

$syntax->syntax_mark_string($input);
is($syntax->xml, $expected_borked, 'syntax_mark_string is back to defaults');


sub load_file
{
   my ($filename) = @_;
   $filename = file('t', $filename)->stringify;
   open my $file, '<', $filename
      or die "error opening file '$filename': $!";

   return do { local $/; <$file> };
}

# vim:ft=perl ts=3 sw=3 expandtab:
