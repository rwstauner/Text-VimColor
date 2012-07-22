#!/usr/bin/env perl

use strict;
use warnings;
use Text::VimColor;
use Path::Class qw( file );
use Timer::Simple;

my $timer = Timer::Simple->new;
#$ENV{TEXT_VIMCOLOR_ALT} = shift @ARGV;

print Text::VimColor->new(
  string => scalar file(__FILE__)->slurp,
  filetype => 'perl',
)->html;

print "\ntook: $timer\n";
