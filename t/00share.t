# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use Text::VimColor;

my @files = qw(
  light.css
  light.xsl
  mark.vim
);

plan tests => scalar @files;

ok( -e Text::VimColor->dist_file($_), 'dist file exists')
  for @files;
