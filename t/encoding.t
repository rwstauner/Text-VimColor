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

sub env_compare {
  my ($env_names, $desc, $get, $exp) = @_;
  $env_names = [$env_names] unless ref $env_names;

  local  %ENV = %ENV;
  delete $ENV{ $_ } for grep { /^(LANG|LC_)/ } keys %ENV;

  my %envs = (
    utf8 => { LANG   => 'en_US.UTF-8' },
    c    => { LC_ALL => 'C' },
  );

  foreach my $env_name ( @$env_names ){
    my $env = $envs{ $env_name };
    local @ENV{ keys %$env } = values %$env;
    my $edesc = sprintf "%s (%s=%s)", $desc, %$env;
    my $got = $get->();
    is $got, $exp, $edesc;
  }
}

my $filetype = 'tvctestsyn';

# use high latin1 chars (for portability)
my $input = decode latin1 => qq[( \x{fe}\x{ea}rl + vim )\n];

ok Encode::is_utf8($input), 'input is a character string';

my $html = decode utf8 =>
  qq[<span class="synSpecial">(</span>] .
  qq[<span class="synComment"> \x{c3}\x{be}\x{c3}\x{aa}rl + </span>] .
  qq[<span class="synTodo">vim</span>] .
  qq[<span class="synComment"> </span>] .
  qq[<span class="synSpecial">)</span>\n];

ok Encode::is_utf8($html), 'expected output is a character string';

# some of these use cases were taken from actual code in other CPAN modules.
# we'll test their usage here to ensure we don't break anything

env_compare [qw(utf8 c)] => 'ascii is fine',
  sub { nothing($filetype, "( hi )\n") },
  qq[<span class="synSpecial">(</span>] .
  qq[<span class="synComment"> hi </span>] .
  qq[<span class="synSpecial">)</span>\n],
;

# This test only passes on vims compiled with +multi_byte.
# As long as the other (explicit) tests pass this one isn't valuable
# but we'll keep it commented for reference/debugging.
##isnt nothing($filetype, $input), $html, 'doing nothing mangles the encoding';

env_compare utf8 => 'use BOM to get vim to honor encoded text',
  sub { prepend_bom($filetype, $input) }, $html;

env_compare utf8 => 'specify encoding by adding "+set fenc=..." to vim_options',
  sub { pass_vim_options(undef, $input, {filetype => $filetype}) }, $html;

done_testing;

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
