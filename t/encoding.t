# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

BEGIN {
  eval 'use Encode qw(encode decode); 1' # core in 5.7.3
    or plan skip_all => 'Encode.pm is required for these tests';
}

my $filetype = 'tvctestsyn';
my $input = qq[( i \x{2764} vim )\n];
my $html =
  qq[<span class="synSpecial">(</span>] .
  qq[<span class="synComment"> i \x{2764} </span>] .
  qq[<span class="synTodo">vim</span>] .
  qq[<span class="synComment"> </span>] .
  qq[<span class="synSpecial">)</span>\n];

# some of these use cases were taken from actual code in other CPAN modules.
# we'll test their usage here to ensure we don't break anything

is prepend_bom($filetype, $input), $html,
  'used BOM to get vim to honor encoded text';

is pass_vim_options(undef, $input, {filetype => $filetype}), $html,
  'specify encoding by adding "+set fenc=..." to vim_options';

done_testing;

# code from other modules copied verbatim

sub prepend_bom {
  my ($lang, $str) = @_;
  # MORITZ/App-Mowyw-v0.7.1/lib/App/Mowyw.pm#L566
  {
    # any encoding will do if vim automatically detects it
    my $vim_encoding = 'utf-8';
    my $BOM = "\x{feff}";
    my $syn = Text::VimColor->new(
            filetype    => $lang,
            string      => encode($vim_encoding, $BOM . $str),
            );
    $str = decode($vim_encoding, $syn->html);
    $str =~ s/^$BOM//;
    return $str;
  };
}

sub pass_vim_options {
  # RJBS/Pod-Elemental-Transfomer-VimHTML-0.093581/lib/Pod/Elemental/Transformer/VimHTML.pm#L15
  {
    my ($self, $str, $param) = @_;

    my $octets = Encode::encode('utf-8', $str, Encode::FB_CROAK);

    my $vim = Text::VimColor->new(
      string   => $octets,
      filetype => $param->{filetype},

      vim_options => [
        qw( -RXZ -i NONE -u NONE -N -n ), "+set nomodeline", '+set fenc=utf-8',
      ],
    );

    my $html_bytes = $vim->html;
    my $html = Encode::decode('utf-8', $html_bytes);

    return $html;
  }
}
