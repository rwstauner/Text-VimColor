# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;

plan tests => 1;

# we could parse version with something like:
# vim -e -s --cmd 'exe "!echo " . version' --cmd q

my $command = 'vim --version';
# is 2>&1 portable?
my @output  = qx/$command 2>&1/;
my $status  = $?;

# print out the vim version for test reports
diag( $command, "\n", @output );

# does vim always exit with 0 for --version?
ok $status == 0, $command;
