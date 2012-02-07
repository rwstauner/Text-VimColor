use strict;
use warnings;

# This module is overly defensive, but hopefully will handle all portability issues
package inc::VimCommand;
our $MIN = '5.4';

use IPC::Open3 'open3'; # core

sub import {
  require_minimum();
}

# TODO: die if `vim --version` =~ /-syntax/ ?
sub require_minimum {
  # vim -h works at least as far back as 5.0 (--version not until 5.2)
  my $output = vim('-h');

  # first line: "VIM - Vi IMproved 5.0 (date)"
  if( my $v = ($output =~ /(\d+\.\d+)/)[0] ){
    if( $v < $MIN ){
      my $msg = <<MINVER;
$output

This module requires version $MIN of vim.
Version $v detected.

If you believe this to be in error please submit a bug report.

MINVER
      $msg =~ s/^/# /mg;
      die $msg;
    }
  }
  else {
    warn "Failed to parse vim version... More failures likely.\n"
  }

  return;
}

sub vim {
  my @args = @_;
  my $output;
  my $timeout = 10;

  # if we pass an arg vim doesn't understand (like --version before v5.2)
  # it will treat it like a filename and wait for input
  # so try not to hang indefinitely if we have an old version.
  eval {
    local $SIG{PIPE} = 'IGNORE';
    local $SIG{ALRM} = sub { die "alarm\n" };

    alarm $timeout;

    my $pid = open3(my ($i, $o), undef, vim => @args);
    waitpid($pid, 0);
    my $stat = $?;

    alarm 0;

    # open3 probably died from this already
    die "Vim not found!\n" unless $stat >= 0;

    local $/;
    $output = <$o>;
  };
  if( my $e = $@ ){
    $e = "Command aborted after $timeout seconds."
      if $e eq "alarm\n";
    die "\n\nError attemting to execute 'vim':\n  $e\n\n";
  }
  return $output;
}

1;
