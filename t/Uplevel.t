#!/usr/bin/perl -Tw

use strict;
use Test::More tests => 14;

BEGIN { use_ok('Sub::Uplevel'); }
can_ok('Sub::Uplevel', 'uplevel');
can_ok(__PACKAGE__, 'uplevel');

#line 11
ok( !caller,                                "caller() not screwed up" );

eval { die "Dying" };
is( $@, "Dying at $0 line 13.\n",           'die() not screwed up' );

sub foo {
    join " - ", caller;
}

sub bar {
    uplevel(1, \&foo);
}

#line 20
is( bar(), "main - $0 - 20",    'uplevel()' );


# Sure, but does it fool die?
sub try_die {
    die "You must die!  I alone am best!";
}

sub wrap_die {
    uplevel(1, \&try_die);
}

# line 31
eval { wrap_die() };
is( $@, "You must die!  I alone am best! at $0 line 31.\n", 'die() fooled' );


# how about warn?
sub try_warn {
    warn "HA!  You don't fool me!";
}

sub wrap_warn {
    uplevel(1, \&try_warn);
}


my $warning;
{ 
    local $SIG{__WARN__} = sub { $warning = join '', @_ };
#line 53
    wrap_warn();
}
is( $warning, "HA!  You don't fool me! at $0 line 53.\n", 'warn() fooled' );


# Carp?
use Carp;
sub try_croak {
    croak("You couldn't fool me on the foolingest day of the year!");
}

sub wrap_croak {
    uplevel 2, \&try_croak;
}

# line 69
eval { wrap_croak() };
is( $@, <<CARP, 'croak() fooled');
You couldn't fool me on the foolingest day of the year! at $0 line 69
	eval {...} called at $0 line 69
CARP

#line 79
ok( !caller,                                "caller() not screwed up" );

eval { die "Dying" };
is( $@, "Dying at $0 line 81.\n",           'die() not screwed up' );



# how about carp?
sub try_carp {
    carp "HA!  You don't fool me!";
}

sub wrap_carp {
    uplevel(2, \&try_carp);
}


$warning = '';
{ 
    local $SIG{__WARN__} = sub { $warning = join '', @_ };
#line 98
    wrap_carp();
}
is( $warning, "HA!  You don't fool me! at $0 line 98\n", 'carp() fooled' );


use lib qw(t/lib);
use Foo;
can_ok( 'main', 'fooble' );


sub core_caller_check {
    return CORE::caller(0);
}

sub caller_check {
    return caller(0);
}

#line 115
ok( eq_array([caller_check()], 
             ['main', $0, 115, 'main::caller_check', (caller_check)[4..9]]),
    'caller check' );
