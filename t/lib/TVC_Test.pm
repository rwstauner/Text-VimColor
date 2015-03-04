# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package # hide from indexer
  TVC_Test;

use Path::Class 0.04 qw( file dir ); # mkpath
use TVC_Share;

sub perl {
  qx{$^X -Ilib -It/lib -MTVC_Share @_};
}

# don't allow user-customized syntax files to throw off test results
$ENV{HOME} = dir('t')->absolute;

if( $^O eq 'MSWin32' ){
  $ENV{USERPROFILE} = $ENV{HOME};

  # NOTE: we'll need to simulate cp -r if we ever add any other files
  my ($src, $dest) =
    map { file(t => $_, qw(syntax tvctestsyn.vim)) }
      qw( .vim vimfiles );

  if( !-e $dest ){
    $dest->parent->mkpath;
    require File::Copy; # core
    File::Copy::copy($src, $dest);
  }
}

use Text::VimColor;
use Path::Class qw(file dir);
use Exporter ();
our @ISA = qw(Exporter);
our @EXPORT = qw(
  ansi_color
  file
  dir
  perl
  slurp_data
  syntax_type_exists
  tvc
  xml_minus_filename
);

sub ansi_color {
  $Text::VimColor::ANSI_COLORS{ $_[0] };
}

sub slurp_data {
  my ($filename) = @_;
  $filename = file('t', 'data', $filename)->stringify;
  open my $file, '<', $filename
    or die "error opening file '$filename': $!";

  return do { local $/; <$file> };
}

sub syntax_type_exists {
  exists $Text::VimColor::SYNTAX_TYPE{ $_[0] };
}

sub tvc {
  main::new_ok('Text::VimColor', [@_])
}

sub xml_minus_filename {
  my ($xml) = @_;
  $xml =~ s{^(<syn:syntax xmlns:syn="[^"]+") filename="[^"]+"(>)}{$1$2}s;
  $xml;
}

1;
