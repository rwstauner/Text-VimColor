#!/usr/bin/perl -w

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Text::VimColor',
   ABSTRACT_FROM => 'lib/Text/VimColor.pm',
   VERSION_FROM => 'lib/Text/VimColor.pm',
   AUTHOR => 'Geoff Richards <qef@laxan.com>',
   EXE_FILES => [ 'text-vimcolor' ],

   #PM_FILTER => 'sed -e \\\'s%!!SHARED!!%$(INSTALLPRIVLIB)%g\\\'',
);
