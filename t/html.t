# vim: set ts=2 sts=2 sw=2 expandtab smarttab:

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;
use File::Temp qw( tempfile );

# TODO: test anything else besides the header?

my $string = "( hi )\n";
my $filetype = 'tvctestsyn';

my ($fh, $path) = tempfile( 'tvc-XXXX', TMPDIR => 1, UNLINK => 1 );
print $fh $string;
close $fh;

# html_full_page false
# (default)

foreach my $test (
  [ string => $string ],
  [ file   => $path ],
){
  my $html = tvc(
    filetype => $filetype,
    @$test,
  )->html;

  unlike $html, qr/<$_>/, "not a full page for $test->[0] - no $_"
    for qw( title style );
}

# html_full_page true
# _html_header()

# possible variations:
my $tests = {
  title => {
    untitled         => 0,
    custom           => 0, # html_title
    input_filename   => 0,
    override         => 0, # html_title overrides filename
  },
  style => {
    inline => {
      dist_file      => 0, # (default)
      custom_css     => 0,
      custom_file    => 0,
      file_handle    => 0,
    },
    link => {
      default_file   => 0,
      custom_url     => 0,
    },
  },
};

{
  # defaults
  test_html(
    {
      string => $string,
    },
    {
      title => [ untitled => '[untitled]' ],
      style => [ inline => dist_file => qr!\.synComment\s*\{!m ],
    },
  );

  # some custom values
  test_html(
    {
      string => $string,
      html_title => 'tvc title',
      html_stylesheet => '.tvc { }',
    },
    {
      title => [ custom => 'tvc title' ],
      style => [ inline => custom_css => qr!\.tvc \{ \}! ],
    }
  );

  test_html(
    {
      file => $path,
      html_stylesheet_file => $path, # this is silly, but sufficient for testing
    },
    {
      title => [ input_filename => $path ],
      style => [ inline => custom_file => qr!\( hi \)\n! ],
    }
  );

  test_html(
    {
      file => $path,
      html_title => 'ignore filename',
      html_stylesheet_file => IO::File->new($path, 'r'), # silly again
    },
    {
      title => [ override => 'ignore filename' ],
      style => [ inline => file_handle => qr!\( hi \)\n! ],
    }
  );

  test_html(
    {
      string => $string,
      html_inline_stylesheet => 0,
    },
    {
      title => [ untitled => '[untitled]' ],
      style => [ link => default_file => qr!file://.+?/light\.css! ],
    }
  );

  test_html(
    {
      string => $string,
      html_inline_stylesheet => 0,
      html_stylesheet_url => 'http://foo.bar/baz.css',
    },
    {
      title => [ untitled => '[untitled]' ],
      style => [ link => custom_url => qr!http://foo.bar/baz.css! ],
    }
  );
}

# confirm that we tested all possibilities

check_all_tested(qw( title ));
check_all_tested(qw( style inline ));
check_all_tested(qw( style link ));

done_testing;

sub test_html {
  my ($options, $tests) = @_;
  my $html = tvc(
    filetype       => $filetype,
    html_full_page => 1,
    %$options,
  )->html;

  # first extract the value we actually want to test out of the html
  # so we can do a plain $val =~ qr// (rather than interpolating)

  {
    my ($key, $exp) = @{ $tests->{title} };
    record_test(title => $key);

    my ($got) = ($html =~ m!<title>(.+?)</title>!);
    is $got, $exp, "title: $key";
  }

  {
    my ($type, $key, $re) = @{ $tests->{style} };
    record_test(style => $type, $key);

    my ($val) = 
      ($type eq 'link'
        ? $html =~ m!<link rel="stylesheet" type="text/css" href="(.+?)" />!
        : $html =~ m!<style>\n(.+)</style>!s);

    if( $val ){
      like $val, $re, "style: $key";
    }
    else {
      ok 0, "failed to match $type style for $key";
      diag $html;
    }
  }
}

sub record_test {
  my $key = pop @_;
  my $t = find_test(@_);
  die "unknown test: @_ $key"
    unless $t && exists $t->{ $key };
  $t->{ $key }++;
}

sub find_test {
  my $find = $tests;
  $find = $find->{ $_ } for @_;
  $find;
}

sub check_all_tested {
  my $check = find_test(@_);
  is( (scalar grep { $_ < 1 } values %$check), 0,
    "all options tested for @_");
}
