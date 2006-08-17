#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
# ex: set ts=8 sts=4 sw=4 expandtab
########################################################################

package Perl::Critic::Utils;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.18_01';
$VERSION = eval $VERSION;    ## no critic

#---------------------------------------------------------------------------
# Exported symbols here

## no critic (AutomaticExport)
our @EXPORT = qw(
    @GLOBALS    $COMMA      $SEVERITY_HIGHEST
    @BUILTINS   $FATCOMMA   $SEVERITY_HIGH
                $COLON      $SEVERITY_MEDIUM
                $SCOLON     $SEVERITY_LOW
                $QUOTE      $SEVERITY_LOWEST
                $DQUOTE
                $SPACE
    $TRUE       $PIPE
    $FALSE      $PERIOD
                $EMPTY


    &is_hash_key
    &is_script
    &is_perl_builtin
    &is_perl_global
    &is_subroutine_name
    &is_method_call
    &is_function_call
    &find_keywords
    &parse_arg_list
    &precedence_of
    &all_perl_files
    &verbosity_to_format
);



#---------------------------------------------------------------------------

our $SEVERITY_HIGHEST = 5;
our $SEVERITY_HIGH    = 4;
our $SEVERITY_MEDIUM  = 3;
our $SEVERITY_LOW     = 2;
our $SEVERITY_LOWEST  = 1;

#---------------------------------------------------------------------------
our $COMMA      = q{,};
our $FATCOMMA   = q{=>};
our $COLON      = q{:};
our $SCOLON     = q{;};
our $QUOTE      = q{'};
our $DQUOTE     = q{"};
our $PERIOD     = q{.};
our $PIPE       = q{|};
our $SPACE      = q{ };
our $EMPTY      = q{};
our $TRUE       = 1;
our $FALSE      = 0;

#---------------------------------------------------------------------------
our @BUILTINS =
  qw(abs         exp              int       readdir      socket     wantarray
     accept      fcntl            ioctl     readline     socketpair warn
     alarm       fileno           join      readlink     sort       write
     atan2       flock            keys      readpipe     splice
     bind        fork             kill      recv         split
     binmode     format           last      redo         sprintf
     bless       formline         lc        ref          sqrt
     caller      getc             lcfirst   rename       srand
     chdir       getgrent         length    require      stat
     chmod       getgrgid         link      reset        study
     chomp       getgrnam         listen    return       sub
     chop        gethostbyaddr    local     reverse      substr
     chown       gethostbyname    localtime rewinddir    symlink
     chr         gethostent       log       rindex       syscall
     chroot      getlogin         lstat     rmdir        sysopen
     close       getnetbyaddr     map       scalar       sysread
     closedir    getnetbyname     mkdir     seek         sysseek
     connect     getnetent        msgctl    seekdir      system
     continue    getpeername      msgget    select       syswrite
     cos         getpgrp          msgrcv    semctl       tell
     crypt       getppid          msgsnd    semget       telldir
     dbmclose    getpriority      next      semop        tie
     dbmopen     getprotobyname   no        send         tied
     defined     getprotobynumber oct       setgrent     time
     delete      getprotoent      open      sethostent   times
     die         getpwent         opendir   setnetent    truncate
     do          getpwnam         ord       setpgrp      uc
     dump        getpwuid         our       setpriority  ucfirst
     each        getservbyname    pack      setprotoent  umask
     endgrent    getservbyport    package   setpwent     undef
     endhostent  getservent       pipe      setservent   unlink
     endnetent   getsockname      pop       setsockopt   unpack
     endprotoent getsockopt       pos       shift        unshift
     endpwent    glob             print     shmctl       untie
     endservent  gmtime           printf    shmget       use
     eof         goto             prototype shmread      utime
     eval        grep             push      shmwrite     values
     exec        hex              quotemeta shutdown     vec
     exists      import           rand      sin          wait
     exit        index            read      sleep        waitpid
);

#Hashify
my %BUILTINS = map { $_ => 1 } @BUILTINS;

#---------------------------------------------------------------------------

#TODO: Should this include punctuations vars?

our @GLOBALS =
  qw(ACCUMULATOR                   INPLACE_EDIT
     BASETIME                      INPUT_LINE_NUMBER NR
     CHILD_ERROR                   INPUT_RECORD_SEPARATOR RS
     COMPILING                     LAST_MATCH_END
     DEBUGGING                     LAST_REGEXP_CODE_RESULT
     EFFECTIVE_GROUP_ID EGID       LIST_SEPARATOR
     EFFECTIVE_USER_ID EUID        OS_ERROR
     ENV                           OSNAME
     EVAL_ERROR                    OUTPUT_AUTOFLUSH
     ERRNO                         OUTPUT_FIELD_SEPARATOR OFS
     EXCEPTIONS_BEING_CAUGHT       OUTPUT_RECORD_SEPARATOR ORS
     EXECUTABLE_NAME               PERL_VERSION
     EXTENDED_OS_ERROR             PROGRAM_NAME
     FORMAT_FORMFEED               REAL_GROUP_ID GID
     FORMAT_LINE_BREAK_CHARACTERS  REAL_USER_ID UID
     FORMAT_LINES_LEFT             SIG
     FORMAT_LINES_PER_PAGE         SUBSCRIPT_SEPARATOR SUBSEP
     FORMAT_NAME                   SYSTEM_FD_MAX
     FORMAT_PAGE_NUMBER            WARNING
     FORMAT_TOP_NAME               PERLDB
     INC ARGV
);

#Hashify
my %GLOBALS = map { $_ => 1 } @GLOBALS;

#-------------------------------------------------------------------------
## no critic 'ProhibitNoisyQuotes';

my %PRECEDENCE_OF = (
  '->'  => 1,       '<'    => 10,      '||'  => 15,
  '++'  => 2,       '>'    => 10,      '..'  => 16,
  '--'  => 2,       '<='   => 10,      '...' => 17,
  '**'  => 3,       '>='   => 10,      '?'   => 18,
  '!'   => 4,       'lt'   => 10,      ':'   => 18,
  '~'   => 4,       'gt'   => 10,      '='   => 19,
  '\\'  => 4,       'le'   => 10,      '+='  => 19,
  '=~'  => 5,       'ge'   => 10,      '-='  => 19,
  '!~'  => 5,       '=='   => 11,      '*='  => 19,
  '*'   => 6,       '!='   => 11,      ','   => 20,
  '/'   => 6,       '<=>'  => 11,      '=>'  => 20,
  '%'   => 6,       'eq'   => 11,      'not' => 22,
  'x'   => 6,       'ne'   => 11,      'and' => 23,
  '+'   => 7,       'cmp'  => 11,      'or'  => 24,
  '-'   => 7,       '&'    => 12,      'xor' => 24,
  '.'   => 7,       '|'    => 13,
  '<<'  => 8,       '^'    => 13,
  '>>'  => 8,       '&&'   => 14,
);

## use critic
#-------------------------------------------------------------------------

sub find_keywords {
    my ( $doc, $keyword ) = @_;
    my $nodes_ref = $doc->find('PPI::Token::Word');
    return if !$nodes_ref;
    my @matches = grep { $_ eq $keyword } @{$nodes_ref};
    return @matches ? \@matches : undef;
}

#-------------------------------------------------------------------------

sub is_perl_builtin {
    my $elem = shift;
    return if !$elem;
    my $name = eval { $elem->isa('PPI::Statement::Sub') } ? $elem->name() : $elem;
    return exists $BUILTINS{ $name };
}

#-------------------------------------------------------------------------

sub is_perl_global {
    my $elem = shift;
    return if !$elem;
    my $var_name = "$elem"; #Convert Token::Symbol to string
    $var_name =~ s{\A [\$@%] }{}mx;  #Chop off the sigil
    return exists $GLOBALS{ $var_name };
}

#-------------------------------------------------------------------------

sub precedence_of {
    my $elem = shift;
    return if !$elem;
    return $PRECEDENCE_OF{ ref $elem ? "$elem" : $elem };
}

#-------------------------------------------------------------------------

sub is_hash_key {
    my $elem = shift;
    return if !$elem;

    #Check curly-brace style: $hash{foo} = bar;
    my $parent = $elem->parent();
    return if !$parent;
    my $grandparent = $parent->parent();
    return if !$grandparent;
    return 1 if $grandparent->isa('PPI::Structure::Subscript');


    #Check declarative style: %hash = (foo => bar);
    my $sib = $elem->snext_sibling();
    return if !$sib;
    return 1 if $sib->isa('PPI::Token::Operator') && $sib eq '=>';

    return;
}

#-------------------------------------------------------------------------

sub is_method_call {
    my $elem = shift;
    return if !$elem;
    my $sib = $elem->sprevious_sibling();
    return if !$sib;
    return $sib->isa('PPI::Token::Operator') && $sib eq q{->};
}

#-------------------------------------------------------------------------

sub is_subroutine_name {
    my $elem  = shift;
    return if !$elem;
    my $sib   = $elem->sprevious_sibling();
    return if !$sib;
    my $stmnt = $elem->statement();
    return if !$stmnt;
    return $stmnt->isa('PPI::Statement::Sub') && $sib eq 'sub';
}

#-------------------------------------------------------------------------

sub is_function_call {
    my $elem  = shift;
    return ! ( is_hash_key($elem) ||
               is_method_call($elem) ||
               is_subroutine_name($elem)
    );
}

#-------------------------------------------------------------------------

sub is_script {
    my $doc = shift;
    my $first_comment = $doc->find_first('PPI::Token::Comment');
    return if !$first_comment;
    return if $first_comment->location()->[0] != 1;
    return $first_comment =~ m{ \A \#\! }mx;
}

#-------------------------------------------------------------------------

sub parse_arg_list {
    my $elem = shift;
    my $sib  = $elem->snext_sibling();
    return if !$sib;

    if ( $sib->isa('PPI::Structure::List') ) {

        #Pull siblings from list
        my $expr = $sib->schild(0);
        return if !$expr;
        return _split_nodes_on_comma( $expr->schildren() );
    }
    else {

        #Gather up remaining nodes in the statement
        my $iter     = $elem;
        my @arg_list = ();

        while ($iter = $iter->snext_sibling() ) {
            last if $iter->isa('PPI::Token::Structure') and $iter eq $SCOLON;
            push @arg_list, $iter;
        }
        return  _split_nodes_on_comma( @arg_list );
    }
}

#---------------------------------

sub _split_nodes_on_comma {
    my @nodes = ();
    my $i = 0;
    for my $node (@_) {
        if ( $node->isa('PPI::Token::Operator') &&
                (($node eq $COMMA) || ($node eq $FATCOMMA)) ) {
            $i++; #Move forward to next 'node stack'
            next;
        }

        #Push onto current 'node stack', or create a new 'stack'
        if ( defined $nodes[$i] ) {
            push @{ $nodes[$i] }, $node;
        }
        else {
            $nodes[$i] = [$node];
        }
    }
    return @nodes;
}

#-----------------------------------------------------------------------------

my %FORMAT_OF = (
    1 => "%f:%l:%c:%m\n",
    2 => "%f: (%l:%c) %m\n",
    3 => "%m at line %l, column %c.  %e.  (Severity: %s)\n",
    4 => "%f: %m at line %l, column %c.  %e.  (Severity: %s)\n",
    5 => "%m at line %l, near '%r'.  (Severity: %s)\n",
    6 => "%f: %m at line %l near '%r'.  (Severity: %s)\n",
    7 => "[%p] %m at line %l, column %c.  (Severity: %s)\n",
    8 => "[%p] %m at line %l, near '%r'.  (Severity: %s)\n",
    9 => "%m at line %l, column %c.\n  %p (Severity: %s)\n%d\n",
   10 => "%m at line %l, near '%r'.\n  %p (Severity: %s)\n%d\n",
);

sub verbosity_to_format {
    my ($verbosity_level) = @_;
    return $FORMAT_OF{ abs $verbosity_level };
}

#-----------------------------------------------------------------------------

sub all_perl_files {

    # Recursively searches a list of directories and returns the paths
    # to files that seem to be Perl source code.  This subroutine was
    # poached from Test::Perl::Critic.

    my %skip_dir = map { ($_,1) } qw( CVS RCS .svn _darcs {arch} .bzr
                                      _build blib );
    my @queue      = @_;
    my @code_files = ();

    while (@queue) {
        my $file = shift @queue;
        if ( -d $file ) {
            opendir my ($dh), $file or next;
            my @newfiles = sort readdir $dh;
            closedir $dh;

            @newfiles = File::Spec->no_upwards(@newfiles);
            @newfiles = grep { !$skip_dir{$_} } @newfiles;
            push @queue, map { File::Spec->catfile($file, $_) } @newfiles;
        }

        if ( (-f $file) && ! _is_backup($file) && _is_perl($file) ) {
            push @code_files, $file;
        }
    }
    return @code_files;
}


#-----------------------------------------------------------------------------
# Decide if it's some sort of backup file

sub _is_backup {
    my ($file) = @_;
    return 1 if $file =~ m{ [.] swp \z}mx;
    return 1 if $file =~ m{ [.] bak \z}mx;
    return 1 if $file =~ m{  ~ \z}mx;
    return 1 if $file =~ m{ \A [#] .+ [#] \z}mx;
    return;
}

#-----------------------------------------------------------------------------
# Returns true if the argument ends with a perl-ish file
# extension, or if it has a shebang-line containing 'perl' This
# subroutine was also poached from Test::Perl::Critic

sub _is_perl {
    my ($file) = @_;

    #Check filename extensions
    return 1 if $file =~ m{ [.] PL          \z}mx;
    return 1 if $file =~ m{ [.] p (?: l|m ) \z}mx;
    return 1 if $file =~ m{ [.] t           \z}mx;

    #Check for shebang
    open my ($fh), '<', $file or return;
    my $first = <$fh>;
    close $fh;

    return 1 if defined $first && ( $first =~ m{ \A \#!.*perl }mx );
    return;
}

#-------------------------------------------------------------------------

1;

__END__

=pod

=head1 NAME

Perl::Critic::Utils - Utility subs and vars for Perl::Critic

=head1 DESCRIPTION

This module exports several static subs and variables that are useful
for developing L<Perl::Critic::Policy> subclasses.  Unless you are
writing Policy modules, you probably don't care about this package.

=head1 EXPORTED SUBS

=over 8

=item C<find_keywords( $doc, $keyword )>

B<DEPRECATED:> Since version 0.11, every Policy is evaluated at each
element of the document.  So you shouldn't need to go looking for a
particular keyword.

Given a L<PPI::Document> as C<$doc>, returns a reference to an array
containing all the L<PPI::Token::Word> elements that match
C<$keyword>.  This can be used to find any built-in function, method
call, bareword, or reserved keyword.  It will not match variables,
subroutine names, literal strings, numbers, or symbols.  If the
document doesn't contain any matches, returns undef.

=item C<is_perl_global( $element )>

Given a L<PPI::Token::Symbol> or a string, returns true if that token
represents one of the global variables provided by the L<English>
module, or one of the builtin global variables like C<%SIG>, C<%ENV>,
or C<@ARGV>.  The sigil on the symbol is ignored, so things like
C<$ARGV> or C<$ENV> will still return true.

=item C<is_perl_builtin( $element )>

Given a L<PPI::Token::Word> or a string, returns true if that token
represents a call to any of the builtin functions defined in Perl
5.8.8

=item C<precedence_of( $element )>

Given a L<PPI::Token::Operator> or a string, returns the precedence of
the operator, where 1 is the highest precedence.  Returns undef if the
precedence can't be determined (which is usually because it is not an
operator).

=item C<is_hash_key( $element )>

Given a L<PPI::Element>, returns true if the element is a hash key.
PPI doesn't distinguish between regular barewords (like keywords or
subroutine calls) and barewords in hash subscripts (which are
considered literal).  So this subroutine is useful if your Policy is
searching for L<PPI::Token::Word> elements and you want to filter out
the hash subscript variety.  In both of the following examples, 'foo'
is considered a hash key:

  $hash1{foo} = 1;
  %hash2 = (foo => 1);

=item C<is_method_call( $element )>

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), returns true if the function is a
method being called on some reference.  Basically, it just looks to see
if the preceding operator is "->".  This is useful for distinguishing
static function calls from object method calls.

=item C<is_subroutine_name( $element )>

Given a L<PPI::Token::Word>, returns true if the element is the name
of a subroutine declaration.  This is useful for distinguishing
barewords and from function calls from subroutine declarations.

=item C<is_function_call( $element )>

Given a L<PPI::Token::Word> returns true if the element appears to be
call to a static function.  Specifically, this function returns true
if C<is_hash_key>, C<is_method_call>, and C<is_subroutine_name> all
return false for the given element.

=item C<parse_arg_list( $element )>

Given a L<PPI::Element> that is presumed to be a function call (which
is usually a L<PPI::Token::Word>), splits the argument expressions
into arrays of tokens.  Returns a list containing references to each
of those arrays.  This is useful because parens are optional when
calling a function, and PPI parses them very differently.  So this
method is a poor-man's parse tree of PPI nodes.  It's not bullet-proof
because it doesn't respect precedence.  In general, I don't like the
way this function works, so don't count on it to be stable (or even
present).

=item C<is_script( $document )>

Given a L<PPI::Document>, test if it starts with C</#!.*perl/>.  If so,
it is judged to be a script instead of a module.

=item C<all_perl_files( @directories )>

Given a list of directories, recursively searches through all the
directories (depth first) and returns a list of paths for all the
files that are Perl code files.  Any administrative files for CVS or
Subversion are skipped, as are things that look like temporary or
backup files.

A Perl code file is:

=over 4

=item * Any file that ends in F<.PL>, F<.pl>, F<.pm>, or F<.t>

=item * Any file that has a first line with a shebang containing 'perl'

=back

=item C<verbosity_to_format( $verbosity_level )>

Given a verbosity level between 1 and 10, returns the corresponding
predefined format string.  These formats are suitable for passing to
the C<set_format> method in L<Perl::Critic::Violation>.  See the
L<perlcritic> documentation for a listing of the predefined formats.

=back

=head1 EXPORTED VARIABLES

=over 8

=item C<@BUILTINS>

B<DEPRECATED:>  Use C<is_perl_builtin()> instead.

This is a list of all the built-in functions provided by Perl 5.8.  I
imagine this is useful for distinguishing native and non-native
function calls.

=item C<@GLOBALS>

B<DEPRECATED:>  Use C<is_perl_global()> instead.

This is a list of all the magic global variables provided by the
L<English> module.  Also includes commonly-used global like C<%SIG>,
C<%ENV>, and C<@ARGV>.  The list contains only the variable name,
without the sigil.

=item C<$COMMA>

=item C<$FATCOMMA>

=item C<$COLON>

=item C<$SCOLON>

=item C<$QUOTE>

=item C<$DQUOTE>

=item C<$PERIOD>

=item C<$PIPE>

=item C<$EMPTY>

=item C<$SPACE>

These character constants give clear names to commonly-used strings
that can be hard to read when surrounded by quotes.

=item C<$SEVERITY_HIGHEST>

=item C<$SEVERITY_HIGH>

=item C<$SEVERITY_MEDIUM>

=item C<$SEVERITY_LOW>

=item C<$SEVERITY_LOWEST>

These numeric constants define the relative severity of violating each
L<Perl::Critic::Policy>.  The C<get_severity> and C<default_severity>
methods of every Policy subclass must return one of these values.

=item C<$TRUE>

=item C<$FALSE>

These are simple booleans. 1 and 0 respectively.  Be mindful of using these
with string equality.  C<$FALSE ne $EMPTY>.

=back

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
