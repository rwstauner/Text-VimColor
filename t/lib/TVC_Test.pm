# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package # hide from indexer
  TVC_Test;

# don't allow user-customized syntax files to throw off test results
$ENV{HOME} = 't';

use Text::VimColor;
use Path::Class qw(file dir);
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(
  file
  dir
  slurp_data
);

sub slurp_data {
  my ($filename) = @_;
  $filename = file('t', 'data', $filename)->stringify;
  open my $file, '<', $filename
    or die "error opening file '$filename': $!";

  return do { local $/; <$file> };
}

1;
