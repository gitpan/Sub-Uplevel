package Sub::Uplevel;

use 5.006;

use strict;
use vars qw($VERSION @ISA @EXPORT $Up_Frames);
$VERSION = 0.05;

# We have to do this so the CORE::GLOBAL versions override the builtins
_setup_CORE_GLOBAL();

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(uplevel);

=head1 NAME

Sub::Uplevel - run a function in a higher stack frame

=head1 SYNOPSIS

  use Sub::Uplevel;

  sub foo {
      print join " - ", caller;
  }

  sub bar {
      uplevel 1, \&foo;
  }

  #line 11
  bar();    # main - foo.plx - 11

=head1 DESCRIPTION

Like Tcl's uplevel() function, but not quite so dangerous.  The idea
is to fool caller().  All the other nasty bits of uplevel are
unnecessary in Perl.


=over 4

=item B<uplevel>

  uplevel $num_frames, \&func, @args;

Makes the given function think it's being executed $num_frames higher
than the current stack level.  So caller() will be caller($num_frames)
for them.

=cut

$Up_Frames = 1;
sub uplevel {
    my($num_frames, $func, @args) = @_;
    local $Up_Frames = $num_frames + 2;

    return $func->(@args);
}


sub _setup_CORE_GLOBAL {
    no warnings 'redefine';

    *CORE::GLOBAL::caller = sub {
        my $height = $_[0] || 0;
        $height += $Up_Frames;
        return undef if $height < 0;
        my @caller = CORE::caller($height);

        if( wantarray ) {
            if( !@_ ) {
                @caller = @caller[0..2];
            }
            return @caller;
        }
        else {
            return $caller[0];
        }
    };

    *CORE::GLOBAL::die = sub {
        my $msg = (!@_ || $_[0] =~ /\n$/) ? 'Died' : join '', @_;

        CORE::die(sprintf("$msg at %s line %d.\n",
                          (caller($Up_Frames - 1))[1,2]));
    };

    *CORE::GLOBAL::warn = sub {
        my $msg = (!@_ || $_[0] =~ /\n$/) ? "Warning: something's wrong"
                                          : join '', @_;

        CORE::warn(sprintf("$msg at %s line %d.\n",
                           (caller($Up_Frames - 1))[1,2]));
    };
}


=back

=head1 BUGS and CAVEATS

Symbol::Uplevel must be used before any code which uses it.

Well, the bad news is uplevel() is about 5 times slower than a normal
function call.  XS implementation anyone?

Blows over any CORE::GLOBAL::caller, die or warn you might have.  Will
be fixed in a newer version.

=head1 AUTHOR

Michael G Schwern E<lt>schwern@pobox.comE<gt>

=head1 SEE ALSO

PadWalker (for the similar idea with lexicals), Hook::LexWrap, 
Tcl's uplevel() at http://www.scriptics.com/man/tcl8.4/TclCmd/uplevel.htm

=cut


1;
