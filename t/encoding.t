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
sub compare (&$$);

my $filetype = 'tvctestsyn';
# use high latin1 chars (but not utf8)
# should we use something that is different from utf8 like decode("iso-8859-15", chr 0xa4)?
my $input = qq[( \x{fe}\x{ea}r\x{4c} \053 vim )\n];
my $html =
  qq[<span class="synSpecial">(</span>] .
  qq[<span class="synComment"> \x{fe}\x{ea}r\x{4c} \053 </span>] .
  qq[<span class="synTodo">vim</span>] .
  qq[<span class="synComment"> </span>] .
  qq[<span class="synSpecial">)</span>\n];

# some of these use cases were taken from actual code in other CPAN modules.
# we'll test their usage here to ensure we don't break anything

compare { nothing($filetype, "( hi )\n") }
  qq[<span class="synSpecial">(</span>] .
  qq[<span class="synComment"> hi </span>] .
  qq[<span class="synSpecial">)</span>\n],
  'ascii is fine';

# This test only passes on vims compiled with +multi_byte.
# As long as the other (explicit) tests pass this one isn't valuable
# but we'll keep it commented for reference/debugging.
##isnt nothing($filetype, $input), $html, 'doing nothing mangles the encoding';

# can we alter $input (en/decode or change the utf8 flag) and get a different result?

compare { prepend_bom($filetype, $input) } $html,
  'used BOM to get vim to honor encoded text';

compare { pass_vim_options(undef, $input, {filetype => $filetype}) } $html,
  'specify encoding by adding "+set fenc=..." to vim_options';

done_testing;

sub compare (&$$) {
  my ($get, $exp, $name) = @_;

  local @ENV{qw(LANG LC_ALL)};
  foreach my $env (
    { LANG   => 'en_US.UTF-8' },
    { LC_ALL => 'C' },
  ){
    local @ENV{ keys %$env } = values %$env;
    local $TODO = 'Encoding tests still under development';
    my $desc = sprintf "%s (%s=%s)", $name, %$env;
    my $got = $get->();
    is $got, $exp, $desc;
  }
}

sub nothing {
  my ($filetype, $input) = @_;
  Text::VimColor->new(filetype => $filetype, string => $input)->html;
}

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
