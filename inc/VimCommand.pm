use strict;
use warnings;

# This module is overly defensive, but hopefully will handle all portability issues
package inc::VimCommand;
#our $MIN = '5.4';
our $MIN = '6.0';

use File::Temp qw( tempfile ); # core
use IO::File; # core
use IPC::Open3 'open3'; # core

# vim -h works at least as far back as 5.0 (--version not until 5.2)
# first line: "VIM - Vi IMproved 5.0 (date)"
our $VERSION_RE = qr/vim .+ ([0-9.]+)/i;

our $INFO = {};

our $MESSAGE = <<MESSAGE;
This module requires vim version $MIN or later
which must be compiled with at least the 'normal' feature set
(--with-features=normal) particularly including +syntax (obviously).

If you believe this to be an error please submit a bug report
including the output of `vim --version` if possible.
MESSAGE

sub import {
  require_minimum_with_message();
}

sub require_minimum_with_message {
  eval {
    require_minimum();
  };
  my $msg = $@;
  if( $msg ){
    $msg .= "\n$MESSAGE\n";
    $msg =~ s/^/# /mg;
    die $msg;
  }
}

sub require_minimum {
  my $info = info_from_script();
  my $ver = sprintf("%0.2f", $info->{version}/100);

  if( !$ver ){
    die "Unable to identify vim version ($ver)\n";
  }
  elsif( $ver < $MIN ){
    $ver =~ s/\.0/./; # 5.08 => 5.8
    die "Vim version $ver too low.\n";
  }
  elsif( !$info->{syntax} ){
    die "Vim does not have the +syntax feature.\n";
  }
  return $ver;
}

sub info_from_script {
  # touch output file
  my $out = write_temp('tvc-out-XXXXXX', '');

  # NOTE: use single quotes, or backslashed double quotes in the '=' expr:
  my $script = write_temp('tvc-script-XXXXXX', <<SCRIPT);
:put ='vim:' . version . ',syn:' . has('syntax') . ','
:0d
:write! $out
:quit!
SCRIPT

  # try
  eval {
    # use IPC::Open3 to prevent STDOUT/ERR from interfering with make/test
    vim(qw(-u NONE -s), $script);

    my $output = do { local $/; IO::File->new($out, 'r')->getline; };

    die "Vim script failed: Output file is empty.\n"
      unless $output;
    die "Failed to parse vim output:\n>$output\n"
      unless $output =~ /^vim:(\d+),syn:(.+?),$/;

    # if there was more info to get we could parse the output more generically
    $INFO = { version => $1, syntax => $2 };
  };
  # catch part 1
  my $e = $@;
  # finally
  unlink($out, $script);
  # catch part 2
  die $e if $e;

  return $INFO;
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

    # read handle before waitpid to avoid hanging (and timing out) on older systems
    $output = do { local $/; <$o>; };

    waitpid($pid, 0);
    #my $stat = $?;

    alarm 0;

    # open3 will probably die if vim isn't found (in unix environments)
    # we can't really trust the exit status to mean anything...
    # vim might exit 1 or 2 (or 0) for -h/--version, cmd.exe exits 1 if not found...
  };
  if( my $e = $@ ){
    $e = "Command aborted after $timeout seconds."
      if $e eq "alarm\n";
    die "Error attemting to execute 'vim':\n  $e\n";
  }
  return $output;
}

sub write_temp {
  my ($template, $text) = @_;
  my ($fh, $path) = tempfile( $template, TMPDIR => 1 );
  print $fh $text;
  close $fh;
  return $path;
}

1;
