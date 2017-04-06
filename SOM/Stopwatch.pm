package Stopwatch;

# Copyright © 2000-2005 Systems of Merritt, Inc.
# Written by Frank Braswell for Hallmark Cards
# October 2000
# November 2004 2.0 

use strict;
# Usage
# use SOM::Stopwatch;
# tie $var, 'Stopwatch';
# $s = 0; # reset timer
# print "$s"; gives elapsed time

sub TIESCALAR
{
	my ( $pkg ) = @_;
	my $obj = time( );
	return ( bless \$obj, $pkg );
} # end sub TIESCALAR

sub FETCH
{
	my ( $r_obj ) = @_;
	# Return time elapsed since last reset
	return ( time( ) - $$r_obj );
} # end sub FETCH

sub STORE
{
	my ( $r_obj, $val ) = @_;
	# Ignore the value. Any write to it is seen as reset
	return ( $$r_obj = time( ) );
} # end sub STORE

1; # end package Stopwatch
