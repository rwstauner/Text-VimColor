# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use Path::Class;

  use Config;
  my $thisperl = $Config{perlpath};
  if ($^O ne 'VMS'){
   $thisperl .= $Config{_exe}
     unless $thisperl =~ m/$Config{_exe}$/i;
  }

my $script = file(bin => 'text-vimcolor')->stringify;
like qx{$thisperl -Ilib $script --format xml t/data/hello.c},
     qr{<syn:PreProc>\#include </syn:PreProc><syn:Constant>&lt;stdio\.h&gt;</syn:Constant>},
     "$script output html ok";

done_testing;
