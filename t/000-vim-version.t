# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More tests => 1;
use inc::VimCommand;

# Include the vim version and feature list in test reports.

diag sprintf "vim --version\n\n%s\n",
  # use the function to portably combine STDOUT and STDERR
  # (since we don't know for sure which one we'll get).
  (eval { inc::VimCommand::vim('--version') } || $@);

# exit status varies, just ok() something
ok 1, 'vim --version';
