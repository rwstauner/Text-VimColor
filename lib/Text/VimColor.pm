# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use warnings;
use strict;

package Text::VimColor;
# ABSTRACT: Syntax highlight text using Vim

use IO::File;
use File::Copy qw( copy );
use File::ShareDir ();
use File::Temp qw( tempfile );
use Path::Class qw( file );
use Carp;
use IPC::Open3 (); # core
use Symbol (); # core

# for backward compatibility
our $SHARED = File::ShareDir::dist_dir('Text-VimColor');

our $VIM_COMMAND = 'vim';
our @VIM_OPTIONS = (qw( -RXZ -i NONE -u NONE -N -n ), "+set nomodeline");
our $NAMESPACE_ID = 'http://ns.laxan.com/text-vimcolor/1';

our %VIM_LET = (
   perl_include_pod => 1,
   'b:is_bash' => 1,
);

our %SYNTAX_TYPE = (
   Comment    => 1,
   Constant   => 1,
   Identifier => 1,
   Statement  => 1,
   PreProc    => 1,
   Type       => 1,
   Special    => 1,
   Underlined => 1,
   Error      => 1,
   Todo       => 1,
);

our %ANSI_COLORS = (
   Comment    =>  'blue',
   Constant   =>  'red',
   Identifier =>  'cyan',
   Statement  =>  'yellow',
   PreProc    =>  'magenta',
   Type       =>  'green',
   Special    =>  'bright_magenta',
   Underlined =>  'underline',
   Error      =>  'on_red',
   Todo       =>  'on_cyan',
);

# Set to true to print the command line used to run Vim.
our $DEBUG = $ENV{TEXT_VIMCOLOR_DEBUG};

sub new {
  my $class = shift;
  my $self = {
    extra_vim_options      => [],
    html_inline_stylesheet => 1,
    xml_root_element       => 1,
    vim_let                => {},
    @_,
  };

  $self->{vim_command} = $VIM_COMMAND
    unless defined $self->{vim_command};

  # NOTE: this should be [ @VIM_OPTIONS ] but \@VIM_OPTIONS is backward-compatible
  $self->{vim_options} = \@VIM_OPTIONS
    unless defined $self->{vim_options};

  # always include these (back-compat)
  $self->{vim_let} = { %VIM_LET, %{ $self->{vim_let} } };

  croak "only one of the 'file' or 'string' options should be used"
    if defined $self->{file} && defined $self->{string};

   bless $self, $class;

   # run automatically if given a source
   $self->_do_markup
      if defined $self->{file} || defined $self->{string};

   return $self;
}

sub dist_file {
  my $self = shift;
  return File::ShareDir::dist_file('Text-VimColor', @_);
}

sub vim_let
{
   my ($self, %option) = @_;

   while (my ($name, $value) = each %option) {
      $self->{vim_let}->{$name} = $value;
   }

   return $self;
}

sub syntax_mark_file
{
   my ($self, $file, %options) = @_;

   local $self->{filetype} = exists $options{filetype} ? $options{filetype}
                                                       : $self->{filetype};

   local $self->{file} = $file;
   $self->_do_markup;

   return $self;
}

sub syntax_mark_string
{
   my ($self, $string, %options) = @_;

   local $self->{filetype} = exists $options{filetype} ? $options{filetype}
                                                       : $self->{filetype};

   local $self->{string} = $string;
   $self->_do_markup;

   return $self;
}

sub ansi
{
   my ($self) = @_;
   my $syntax = $self->marked;

   require Term::ANSIColor;
  # allow the environment to overwrite:
  my %colors = (
    %ANSI_COLORS,
    $ENV{TEXT_VIMCOLOR_ANSI} ? split(/\s*[=;]\s*/, $ENV{TEXT_VIMCOLOR_ANSI}) : ()
  );

  local $_;

  # Term::ANSIColor didn't support bright values until version 3
  # Handle this here to cover custom colors and not require T::AC until needed
  if( Term::ANSIColor->VERSION < 3 ){
    s/bright_// for values %colors;
  }

  # compared to join/map or foreach/my this benched as the fastest:
  my $ansi = '';
  for ( @$syntax ){
    $ansi .= $_->[0] eq ''
      ? $_->[1]
      : Term::ANSIColor::colored([ $colors{ $_->[0] } ], $_->[1]);
  }

   return $ansi;
}

sub html
{
   my ($self) = @_;
   my $syntax = $self->marked;

   my $html = '';
   $html .= $self->_html_header
      if $self->{html_full_page};

   foreach (@$syntax) {
      $html .= _xml_escape($_->[1]), next
         if $_->[0] eq '';

      $html .= "<span class=\"syn$_->[0]\">" .
               _xml_escape($_->[1]) .
               '</span>';
   }

   $html .= "</pre>\n\n </body>\n</html>\n"
      if $self->{html_full_page};

   return $html;
}

sub xml
{
   my ($self) = @_;
   my $syntax = $self->marked;

   my $xml = '';
   if ($self->{xml_root_element}) {
      my $filename = $self->input_filename;
      $xml .= "<syn:syntax xmlns:syn=\"$NAMESPACE_ID\"";
      $xml .= ' filename="' . _xml_escape($filename) . '"'
         if defined $filename;;
      $xml .= '>';
   }

   foreach (@$syntax) {
      $xml .= _xml_escape($_->[1]), next
         if $_->[0] eq '';

      $xml .= "<syn:$_->[0]>" .
              _xml_escape($_->[1]) .
              "</syn:$_->[0]>";
   }

   $xml .= "</syn:syntax>\n"
      if $self->{xml_root_element};

   return $xml;
}

sub marked
{
   my ($self) = @_;

   exists $self->{syntax}
      or croak "an input file or string must be specified, either to 'new' or".
               " 'syntax_mark_file/string'";

   return $self->{syntax};
}

sub input_filename
{
   my ($self) = @_;

   my $file = $self->{file};
   return $file if defined $file && !ref $file;

   return;
}

# Return a string consisting of the start of an XHTML file, with a stylesheet
# either included inline or referenced with a <link>.
sub _html_header
{
   my ($self) = @_;

   my $input_filename = $self->input_filename;
   my $title = defined $self->{html_title} ? _xml_escape($self->{html_title})
             : defined $input_filename     ? _xml_escape($input_filename)
             : '[untitled]';

   my $stylesheet;
   if ($self->{html_inline_stylesheet}) {
      $stylesheet = "<style>\n";
      if ($self->{html_stylesheet}) {
         $stylesheet .= _xml_escape($self->{html_stylesheet});
      }
      else {
         my $file = $self->{html_stylesheet_file};
         $file = $self->dist_file('light.css')
            unless defined $file;
         unless (ref $file) {
            $file = IO::File->new($file, 'r')
               or croak "error reading stylesheet '$file': $!";
         }
         local $/;
         $stylesheet .= _xml_escape(<$file>);
      }
      $stylesheet .= "</style>\n";
   }
   else {
      $stylesheet =
         "<link rel=\"stylesheet\" type=\"text/css\" href=\"" .
         _xml_escape($self->{html_stylesheet_url} ||
                     "file://${\ file($self->dist_file('light.css'))->as_foreign('Unix') }") .
         "\" />\n";
   }

   "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"" .
   " \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n" .
   "<html>\n" .
   " <head>\n" .
   "  <title>$title</title>\n" .
   "  $stylesheet" .
   " </head>\n" .
   " <body>\n\n" .
   "<pre>";
}

# Return a string safe to put in XML text or attribute values.  It doesn't
# escape single quotes (&apos;) because we don't use those to quote
# attribute values.
sub _xml_escape
{
   my ($s) = @_;
   $s =~ s/&/&amp;/g;
   $s =~ s/</&lt;/g;
   $s =~ s/>/&gt;/g;
   $s =~ s/"/&quot;/g;
   return $s;
}

# Actually run Vim and turn the script's output into a datastructure.
sub _do_markup
{
   my ($self) = @_;
   my $vim_syntax_script = $self->dist_file('mark.vim');

   croak "Text::VimColor syntax script '$vim_syntax_script' not installed"
      unless -f $vim_syntax_script && -r $vim_syntax_script;

   if ($DEBUG) {
      print STDERR __PACKAGE__."::_do_markup: script: $vim_syntax_script\n";
   }

   my $filename = $self->{file};
   my $input_is_temporary = 0;
   if (ref $self->{file}) {
      my $fh;
      ($fh, $filename) = tempfile();
      $input_is_temporary = 1;

      binmode $self->{file};
      binmode $fh;
      copy($self->{file}, $fh);
   }
   elsif (exists $self->{string}) {
      my $fh;
      ($fh, $filename) = tempfile();
      $input_is_temporary = 1;

      binmode $fh;
      print $fh (ref $self->{string} ? ${$self->{string}} : $self->{string});
   }
   else {
      croak "input file '$filename' not found"
         unless -f $filename;
      croak "input file '$filename' not accessible"
         unless -r $filename;
   }

   # Create a temp file to put the output in.
   my ($out_fh, $out_filename) = tempfile();

   # Create a temp file for the 'script', which is given to vim
   # with the -s option.  This is necessary because it tells Vim not
   # to delay for 2 seconds after displaying a message.
   my ($script_fh, $script_filename) = tempfile();
   my $filetype = $self->{filetype};
   my $filetype_set = defined $filetype ? ":set filetype=$filetype" : '';
   my $vim_let = $self->{vim_let};

  # on linux '-s' is fast and '--cmd' adds the 2-second startup delay
  # are there situations where --cmd is necessary or useful?
  # XXX: for debugging, may be removed in the future
  my $use_cmd_opt = $ENV{TEXT_VIMCOLOR_CMD_OPT};

  # Specify filename as argument to command (rather than using :edit in script).
  # If using --cmd then the filename needs to be in the script.
  # For some reason windows doesn't seem to like the filename being in the arg list.
  # Are there other times that this is needed?
  my $file_as_arg = ($use_cmd_opt || $^O ne 'MSWin32');

  my @script_lines = (
    map { "$_\n" }
      # do :edit before :let or the buffer variables may get reset
      (!$file_as_arg ? ":edit $filename" : ()),
      (
        map  { ":let $_=$vim_let->{$_}" }
        grep { defined  $vim_let->{$_} }
          keys %$vim_let
      ),
      ':filetype on',
       $filetype_set,
      ":source $vim_syntax_script",
      ":write! $out_filename",
      ':qall!',
  );

  print STDERR map { __PACKAGE__ . " | $_" } @script_lines if $DEBUG;

   print $script_fh @script_lines;
   close $script_fh;

   $self->_run(
      $self->{vim_command},
      $self->vim_options,
      ($file_as_arg ? $filename : ()),
      (
        $use_cmd_opt
          ? ( '--cmd' => "silent! so $script_filename" )
          : ( '-s'    => $script_filename )
      ),
   );

   unlink $filename
      if $input_is_temporary;
   unlink $out_filename;
   unlink $script_filename;

   my $data = do { local $/; <$out_fh> };

   # Convert line endings to ones appropriate for the current platform.
   $data =~ s/\x0D\x0A?/\n/g;

   my $syntax = [];
   LOOP: {
      _add_markup($syntax, $1, $2), redo LOOP
         if $data =~ /\G>(.*?)>(.*?)<\1</cgs;
      _add_markup($syntax, '', $1), redo LOOP
         if $data =~ /\G([^<>]+)/cgs;
   }

   $self->{syntax} = $syntax;
}

# Given an array ref ($syntax), we add a new syntax chunk to it, unescaping
# the text and making sure that consecutive chunks of the same type are
# merged.
sub _add_markup
{
   my ($syntax, $type, $text) = @_;

   # TODO: make this optional
   # (https://github.com/petdance/vim-perl/blob/master/t/01_highlighting.t#L12)

   # Ignore types we don't know about.  At least one syntax file (xml.vim)
   # can produce these.  It happens when a syntax type isn't 'linked' to
   # one of the predefined types.
   $type = ''
      unless exists $SYNTAX_TYPE{$type};

   # Unescape ampersands and pointies.
   $text =~ s/&l/</g;
   $text =~ s/&g/>/g;
   $text =~ s/&a/&/g;

   if (@$syntax && $syntax->[-1][0] eq $type) {
      # Concatenate consecutive bits of the same type.
      $syntax->[-1][1] .= $text;
   }
   else {
      # A new chunk of marked-up text.
      push @$syntax, [ $type, $text ];
   }
}

# This is a private internal method which runs a program.
# It takes a list of the program name and arguments.
sub _run
{
   my ($self, $prog, @args) = @_;

   if ($DEBUG) {
      print STDERR __PACKAGE__."::_run: $prog " .
            join(' ', map { "'$_'" } @args) . "\n";
   }

  {
    my ($in, $out) = (Symbol::gensym(), Symbol::gensym());
    my $err_fh = Symbol::gensym();

    my $pid = IPC::Open3::open3($in, $out, $err_fh, $prog => @args);

    # close these to avoid any ambiguity that might cause this to block
    # (see also the paragraph about "select" in IPC::Open3)
    close($in);
    close($out);

    # read handle before waitpid to avoid hanging on older systems
    my $errout = do { local $/; <$err_fh> };

      my $gotpid = waitpid($pid, 0);
      croak "couldn't run the program '$prog'" if $gotpid == -1;
      my $error = $? >> 8;
      if ($error) {
         $errout =~ s/\n+\z//;
         my $details = $errout eq '' ? '' :
                       "\nVim wrote this error output:\n$errout\n";
         croak "$prog returned an error code of '$error'$details";
      }
   }
}

sub vim_options {
  my ($self) = @_;
  return (
    @{ $self->{vim_options} },
    @{ $self->{extra_vim_options} },
  );
}

1;

=head1 SYNOPSIS

   use Text::VimColor;
   my $syntax = Text::VimColor->new(
      file => $0,
      filetype => 'perl',
   );

   print $syntax->html;
   print $syntax->xml;
   print $syntax->ansi;

=head1 DESCRIPTION

This module tries to markup text files according to their syntax.  It can
be used to produce web pages with pretty-printed colorful source code
samples.  It can produce output in the following formats:

=over 4

=item HTML

Valid XHTML 1.0, with the exact coloring and style left to a CSS stylesheet

=item XML

Pieces of text are marked with XML elements in a simple vocabulary,
which can be converted to other formats, for example, using XSLT

=item Perl array

A simple Perl data structure, so that Perl code can be used to turn it
into whatever is needed

=item ANSI Escape Sequences

A string marked with L<Term::ANSIColor>
suitable for printing to a terminal.

=back

This module works by running the Vim text editor and getting it to apply its
excellent syntax highlighting (aka 'font-locking') to an input file, and mark
pieces of text according to whether it thinks they are comments, keywords,
strings, etc.  The Perl code then reads back this markup and converts it
to the desired output format.

This is an object-oriented module.  To use it, create an object with
the L</new> function (as shown in L</SYNOPSIS>) and then call methods
to get the markup out.

=method new

  my $tvc = Text::VimColor->new(%options)

Returns a syntax highlighting object.  Pass it a hash of options.

The following options are recognized:

=over 4

=item file

The file to syntax highlight.  Can be either a filename or an open file handle.

Note that using a filename might allow Vim to guess the file type from its
name if none is specified explicitly.

If the file isn't specified while creating the object, it can be given later
in a call to the L</syntax_mark_file> method (see below), allowing a single
C<Text::VimColor> object to be used with multiple input files.

=item string

Use this to pass a string to be used as the input.  This is an alternative
to the C<file> option.  A reference to a string will also work.

The L</syntax_mark_string> method is another way to use a string as input.

=item filetype

Specify the type of file Vim should expect, in case Vim's automatic
detection by filename or contents doesn't get it right.  This is
particularly important when providing the file as a string or file
handle, since Vim won't be able to use the file extension to guess
the file type.

The file types recognized by Vim are short strings like 'perl' or 'lisp'.
They are the names of files in the 'syntax' directory in the Vim
distribution.

This option, whether or not it is passed to L</new>, can be overridden
when calling L</syntax_mark_file> and L</syntax_mark_string>, so you can
use the same object to process multiple files of different types.

=item html_full_page

By default the L</html> output method returns a fragment of HTML, not a
full file.  To make useful output this must be wrapped in a C<< <pre> >>
element and a stylesheet must be included from somewhere.  Setting the
L</html_full_page> option will instead make the L</html> method return a
complete stand-alone XHTML file.

Note that while this is useful for testing, most of the time you'll want to
put the syntax highlighted source code in a page with some other content,
in which case the default output of the L</html> method is more appropriate.

=item html_inline_stylesheet

Turned on by default, but has no effect unless L</html_full_page> is also
enabled.

This causes the CSS stylesheet defining the colors to be used
to render the markup to be be included in the HTML output, in a
C<< <style> >> element.  Turn it off to instead use a C<< <link> >>
to reference an external stylesheet (recommended if putting more than one
page on the web).

=item html_stylesheet

Ignored unless C<html_full_page> and C<html_inline_stylesheet> are both
enabled.

This can be set to a stylesheet to include inline in the HTML output (the
actual CSS, not the filename of it).

=item html_stylesheet_file

Ignored unless C<html_full_page> and C<html_inline_stylesheet> are both
enabled.

This can be the filename of a stylesheet to copy into the HTML output,
or a file handle to read one from.  If neither this nor C<html_stylesheet>
are given, the supplied stylesheet F<light.css> will be used instead.

=item html_stylesheet_url

Ignored unless C<html_full_page> is enabled and C<html_inline_stylesheet>
is disabled.

This can be used to supply the URL (relative or absolute) or the stylesheet
to be referenced from the HTML C<< <link> >> element in the header.
If this isn't given it will default to using a C<file://> URL to reference
the supplied F<light.css> stylesheet, which is only really useful for testing.

=item xml_root_element

By default this is true.  If set to a false value, XML output will not be
wrapped in a root element called C<< <syn:syntax> >>, but will be otherwise the
same.  This could allow XML output for several files to be concatenated,
but to make it valid XML a root element must be added.  Disabling this
option will also remove the binding of the namespace prefix C<syn:>, so
an C<xmlns:syn> attribute would have to be added elsewhere.

=item vim_command

The name of the executable which will be run to invoke Vim.
The default is C<vim>.

=item vim_options

A reference to an array of options to pass to Vim.  The default options are:

  [qw( -RXZ -i NONE -u NONE -N -n ), "+set nomodeline"]

You can overwrite the default options by setting this.
To merely append additional options to the defaults
use C<extra_vim_options>.

=item extra_vim_options

A reference to an array of additional options to pass to Vim.
These are appended to the default C<vim_options>.

=item vim_let

A reference to a hash of options to set in Vim before the syntax file
is loaded.  Each of these is set using the C<let> command to the value
specified.  No escaping is done on the values, they are executed exactly
as specified.

Values in this hash override some default options.  Use a value of
C<undef> to prevent a default option from being set at all.  The
defaults are as follows:

   (
      perl_include_pod => 1,     # Recognize POD inside Perl code
      'b:is_bash' => 1,          # Allow Bash syntax in shell scripts
   )

These settings can be modified later with the C<vim_let()> method.

=back

=method vim_let

  $tvc->vim_let( %variables );
  $tvc->vim_let( perl_no_extended_vars => 1 );

Change the options that are set with the Vim C<let> command when Vim
is run.  See L</new> for details.

=method syntax_mark_file

  $tvc->syntax_mark_file( $file, %options )

Mark up the specified file.  Subsequent calls to the output methods will then
return the markup.  It is not necessary to call this if a C<file> or C<string>
option was passed to L</new>.

Returns the object it was called on, so an output method can be called
on it directly:

  foreach (@files) {
    print $tvc->syntax_mark_file($_)->html;
  }

You can override the file type set in new() by passing in a C<filetype>
option, like so:

  $tvc->syntax_mark_file($filename, filetype => 'perl');

This option will only affect the syntax coloring for that one call,
not for any subsequent ones on the same object.

=method syntax_mark_string

  $tvc->syntax_mark_string($string, %options)

Does the same as C<syntax_mark_file> (see above) but uses a string as input.
The I<string> can also be a reference to a string.

Returns the object it was called on.  Supports the C<filetype> option
just as C<syntax_mark_file> does.

=method ansi

Return the string marked with ANSI escape sequences (using L<Term::ANSIColor>)
based on the Vim syntax coloring of the input file.

This is the default format for the included L<text-vimcolor> script
which makes it like a colored version of C<cat(1)>.

You can alter the color scheme using the C<TEXT_VIMCOLOR_ANSI>
environment variable in the format of C<< "SynGroup=color;" >>.
For example:

   TEXT_VIMCOLOR_ANSI='Comment=green;Statement = magenta; '

=method html

Return XHTML markup based on the Vim syntax coloring of the input file.

Unless the C<html_full_page> option is set, this will only return a fragment
of HTML, which can then be incorporated into a full page.  The fragment
will be valid as either HTML or XHTML.

The only markup used for the actual text will be C<< <span> >> elements
wrapped around appropriate pieces of text.  Each one will have a C<class>
attribute set to a name which can be tied to a foreground and background
color in a stylesheet.  The class names used will have the prefix C<syn>,
for example C<synComment>.
For the full list see L</HIGHLIGHTING TYPES>.

=method xml

Returns markup in a simple XML vocabulary.  Unless the C<xml_root_element>
option is turned off (it's on by default) this will produce a complete XML
document, with all the markup inside a C<< <syntax> >> element.

This XML output can be transformed into other formats, either using programs
which read it with an XML parser, or using XSLT.  See the
L<text-vimcolor>(1) program for an example of how XSLT can be used with
XSL-FO to turn this into PDF.

The markup will consist of mixed content with elements wrapping pieces
of text which Vim recognized as being of a particular type.  The names of
the elements used are the ones listed in L</HIGHLIGHTING TYPES>.
below.

The C<< <syntax> >> element will declare the namespace for all the
elements produced, which will be C<http://ns.laxan.com/text-vimcolor/1>.
It will also have an attribute called C<filename>, which will be set to the
value returned by the C<input_filename> method, if that returns something
other than undef.

The XML namespace is also available as C<$Text::VimColor::NAMESPACE_ID>.

=method marked

This output function returns the marked-up text in the format which the module
stores it in internally.  The data looks like this:

   use Data::Dumper;
   print Dumper($tvc->marked);

   # produces
   $VAR1 = [
      [ 'Statement', 'my' ],
      [ '', ' ' ],
      [ 'Identifier', '$syntax' ],
      [ '', ' = ' ],
       ...
   ];

This method returns a reference to an array.  Each item in the
array is itself a reference to an array of two items: the first is one of
the names listed in L<HIGHLIGHTING TYPES> (or an empty string if none apply),
and the second is the actual piece of text.

=method input_filename

Returns the filename of the input file, or undef if a filename wasn't
specified.

=method dist_file

  my $full_path = Text::VimColor->dist_file($file);
  my $xsl = $tvc->dist_file('light.xsl');

Returns the path to the specified file that is part of the C<Text-VimColor> dist
(for example, F<mark.vim> or F<light.css>).

Can be called as an instance method or a class method.

This is a thin wrapper around L<File::ShareDir/dist_file>
and is mostly for internal use.

=head1 HIGHLIGHTING TYPES

The following list gives the names of highlighting types which will be
set for pieces of text.  For HTML output, these will appear as CSS class
names, except that they will all have the prefix C<syn> added.  For XML
output, these will be the names of elements which will all be in the
namespace C<http://ns.laxan.com/text-vimcolor/1>.

Here is the complete list:

=for :stopwords PreProc Todo

=for :list
* Comment
* Constant
* Identifier
* Statement
* PreProc
* Type
* Special
* Underlined
* Error
* Todo

=head1 RELATED MODULES

These modules allow C<Text::VimColor> to be used more easily in particular
environments:

=for :list
* L<Apache::VimColor>
* L<Kwiki::VimMode>
* L<Template-Plugin-VimColor>

=head1 SEE ALSO

=over 4

=item L<text-vimcolor>(1)

A simple command line interface to this module's features.  It can be used
to produce HTML and XML output,
print to the screen (like a colored C<cat(1)>),
and can also generate PDF output using
an XSLT/XSL-FO stylesheet and the FOP processor.

=item http://www.vim.org/

Everything to do with the Vim text editor.

=back

=head1 BUGS

Quite a few, actually:

=over 4

=item *

Apparently this module doesn't always work if run from within a 'gvim'
window, although I've been unable to reproduce this so far.
CPAN RT #11555.

=item *

There should be a way of getting a DOM object back instead of an XML string.

=item *

It should be possible to choose between HTML and XHTML, and perhaps there
should be some control over the DOCTYPE declaration when a complete file is
produced.

=item *

With Vim versions earlier than 6.2 there is a 2 second delay each time
Vim is run.

=item *

This requires vim version 6 (it has since 2003).
There may be workarounds to support version 5 (technically 5.4+).
Upgrading vim is a much better idea, but if you need support
for older versions please file a ticket (with patches if possible).

=back

=for :stopwords TODO syntaxes

=head1 TODO

=for :list
* L<https://github.com/rwstauner/Text-VimColor/issues/1>
* option for 'set number'
* make global vars available through methods
* list available syntaxes? (see L<IkiWiki::Plugin::syntax::Vim>)

=for :stopwords Moolenaar

=head1 ACKNOWLEDGEMENTS

The Vim script F<mark.vim> is a crufted version of F<2html.vim> by
Bram Moolenaar E<lt>Bram@vim.orgE<gt> and
David Ne\v{c}as (Yeti) E<lt>yeti@physics.muni.czE<gt>.

=cut
