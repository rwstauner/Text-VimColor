#!/usr/bin/perl -w

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Text::VimColor',
   ABSTRACT_FROM => 'lib/Text/VimColor.pm',
   VERSION_FROM => 'lib/Text/VimColor.pm',
   AUTHOR => [
      'Geoff Richards <qef@laxan.com>',
      'Randy Stauner <rwstauner@cpan.org>',
   ],
   NO_META => 1,
   EXE_FILES => [ 'text-vimcolor' ],

   PREREQ_PM => {
      'Path::Class' => 0.02,
      'Term::ANSIColor' => 0,
   },
   dist => {
      TAR => 'ptar',
      TARFLAGS => '-c -C -f',
   },
);

# vi:ts=3 sw=3 expandtab
