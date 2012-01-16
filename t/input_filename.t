# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use TVC_Test;

is tvc()->input_filename, undef,
  'undef without filename or string specified';

my $file = file(qw(t data hello.c))->stringify;

is tvc(file => $file)->input_filename, $file,
  'matches file provided';

open(my $fh, '<', $file);

is tvc(file => $fh)->input_filename, undef,
  'undef for handles';

close $fh;

is tvc(string => 'if(1){}')->input_filename, undef,
  'undef when input is a string';

done_testing;
