#!/usr/bin/perl -w

use Test::More tests => 1;

my $death = `$^X -I"lib" -I"blib/lib" -e "use Sub::Uplevel;  die" 2>&1`;
is( $death, "Died at -e line 1.\n" );

