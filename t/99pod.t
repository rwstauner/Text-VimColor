# Validate the POD documentation in all Perl modules (*.pm) under the 'lib'
# directory.  Prints a warning if no documentation was found (because that
# probably means you should write some).

use strict;
use warnings;
use Test;
use File::Find;
use Pod::Checker;
use File::Temp qw( tempfile );
use IO::File;


# Each test is for a particular '.pm' file, so we need to find how many
# there are before we plan the tests.
my @pm;
find({ wanted => \&wanted, no_chdir => 1 }, 'lib');

sub wanted
{
   return unless -f;
   return unless /\.pm$/;
   push @pm, $_;
}

plan tests => scalar @pm;


foreach (@pm) {
   # Warnings are sent to a temporary file.
   my ($log_file, $log_filename) = tempfile();

   my $s = podchecker($_, $log_file, '-warnings' => 2);
   close $log_file;

   warn "\n$_: no documentation.\n" if $s < 0;
   if ($s > 0) {
      $log_file = IO::File->new($log_filename, 'r')
         or die "$0: error rereading log file '$log_filename': $!\n";
      my $log = do { local $/; <$log_file> };
      warn "\n$log\n";
   }

   ok($s <= 0);
   unlink $log_filename;
}

# Local Variables:
# mode: perl
# perl-indent-level: 3
# End:
# vim:ft=perl ts=3 sw=3 expandtab:
