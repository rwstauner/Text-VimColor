# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;

plan tests => 1;

my $command = 'vim --version';
# is 2>&1 portable?
my @output  = qx/$command 2>&1/;
my $status  = $?;

# print out the vim version for test reports
diag( $command, "\n", @output );

# does vim always exit with 0 for --version?
ok $status == 0, $command;

# does this work consistently/portably?
my $numver = eval {
  local $SIG{ALRM} = sub { die "timed out\n" };
  alarm 10;
  my $v = eval { qx/vim -e --cmd "echo version" --cmd q 2>&1/; };
  alarm 0;
  $v ? ($v =~ /(\d+)/)[0] : $@;
};
if ($@) {
  $numver = $@;
}
diag "numeric vim version: " . $numver;
