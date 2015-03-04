# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use Text::VimColor;
use lib 't/lib';
use TVC_Test;

my %files =
  map { ($_ => Text::VimColor->dist_file($_)) }
    qw(
      define_all.vim
      light.css
      light.xsl
      mark.vim
    );

plan tests => scalar keys %files;

while( my ($name, $path) = each %files ){
  ok( -e $path, "dist file '$name' exists at $path")
}
