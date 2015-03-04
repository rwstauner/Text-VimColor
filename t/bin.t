# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;
use Path::Class;

my $script = file(bin => 'text-vimcolor')->stringify;

sub run {
  perl(qq{$script @_});
}

{
  like run(qw{--format xml t/data/hello.c}),
     qr{<syn:PreProc>\#include </syn:PreProc><syn:Constant>&lt;stdio\.h&gt;</syn:Constant>},
     "$script output html ok";

  like run(qw{--format xml --all-syntax-groups t/data/hello.c}),
     qr{<syn:Include>\#include </syn:Include><syn:String>&lt;stdio\.h&gt;</syn:String>},
     "$script output html ok";
}

done_testing;
