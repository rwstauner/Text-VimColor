# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
# Check that things which should produce identical output do.

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TVC_Test;

# If the version of Vim is too old to do the right shell-script highlighting,
# then just don't bother.
{
   open my $vim, '-|', 'vim --version'
      or die "error running 'vim --version': $!";
   my $line = <$vim>;
   die "couldn't read version from 'vim --version'"
      unless defined $line;
   if ($line =~ / (\d+)\.(\d+) / && ($1 >= 7 || ($1 == 6 && $2 >= 3))) {
      plan tests => 7;
   }
   else {
      plan skip_all => 'need Vim 6.3 for this to work';
   }
}

my $input                = slurp_data('shell.sh');
my $expected_sh_output   = slurp_data('shell-sh.xml');
my $expected_bash_output = slurp_data('shell-bash.xml');


# First test setting 'let' values in the constructor.

{
   my $syntax = Text::VimColor->new(
      string  => $input,
      filetype => 'sh',
   );
   is($syntax->xml, $expected_bash_output,
      'by default shell should enable bash features');
}

{
   my $syntax = Text::VimColor->new(
      string  => $input,
      filetype => 'sh',
      vim_let => { 'b:is_bash' => undef },
   );
   is($syntax->xml, $expected_sh_output,
      'shell should disable bash features with b:is_bash=undef');
}

{
   my $syntax = Text::VimColor->new(
      string  => $input,
      filetype => 'sh',
      vim_let => { 'b:is_bash' => 1 },
   );
   is($syntax->xml, $expected_bash_output,
      'shell should enable bash features with b:is_bash=1');
}


# now test setting 'let' values with the 'vim_let' method.

{
   my $syntax = Text::VimColor->new(
      filetype => 'sh',    # TODO - move to syntax_mark_string()
   );
   $syntax->syntax_mark_string($input);
   is($syntax->xml, $expected_bash_output,
      'by default shell should enable bash features (two-step marking)');
}

{
   my $syntax = Text::VimColor->new(
      filetype => 'sh',    # TODO - move to syntax_mark_string()
   );
   $syntax->vim_let('b:is_bash' => undef);
   $syntax->syntax_mark_string($input);
   is($syntax->xml, $expected_sh_output,
      'shell should disable bash features with vim_let(b:is_bash=>undef)');
}

{
   my $syntax = Text::VimColor->new(
      filetype => 'sh',    # TODO - move to syntax_mark_string()
   );
   $syntax->vim_let(foo => '"bar"', 'b:is_bash' => undef);
   $syntax->syntax_mark_string($input);
   is($syntax->xml, $expected_sh_output,
      'disable bash features with vim_let(foo=>"bar", b:is_bash=>undef)');
}

{
   my $syntax = Text::VimColor->new(
      filetype => 'sh',    # TODO - move to syntax_mark_string()
   );
   $syntax->vim_let('b:is_bash' => 1);
   $syntax->syntax_mark_string($input);
   is($syntax->xml, $expected_bash_output,
      'shell should enable bash features with vim_let(b:is_bash=>1)');
}
