# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Test that options in calls syntax_mark_file() and syntax_mark_string()
# override the ones passed to new().

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

plan tests => 4;

my $syntax = Text::VimColor->new(
   filetype => 'perl',
);

my $input_filename  = file('t', 'data', 'table.sql')->stringify;
my $input           = slurp_data('table.sql');
my $expected_sql    = slurp_data('table-sql.xml');
my $expected_borked = slurp_data('table-borked.xml');

$syntax->syntax_mark_file($input_filename, filetype => 'sql');
my $output = xml_minus_filename($syntax->xml);
is($output, $expected_sql, 'syntax_mark_file options override defaults');

$syntax->syntax_mark_file($input_filename);
$output = xml_minus_filename($syntax->xml);
is($output, $expected_borked, 'syntax_mark_file goes back to defaults');

$syntax->syntax_mark_string($input, filetype => 'sql');
is($syntax->xml, $expected_sql, 'syntax_mark_string options override defaults');

$syntax->syntax_mark_string($input);
is($syntax->xml, $expected_borked, 'syntax_mark_string is back to defaults');
