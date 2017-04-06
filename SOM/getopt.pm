package SOM::getopt;

# Copyright � 2000-2005 Systems of Merritt, Inc.
# Written by Frank Braswell for Hallmark Cards
# October 2000
# November 2004 2.0
# September 2006 2.0.3

# Update 4-30-10 remove references to AppleScript

# This module will process and handle the command
# switches and options.

# RIPSAW -h -m"Mexico" -d -?

require Exporter;
@ISA = qw(Exporter);
#@EXPORT_OK = qw( initstuff processjob OpenDocuments keypress);
@EXPORT = qw( gethtml getdebug getmadeincountry getimageshow getsecondaryprocess getquarkclip gethktemplate );
use strict;
use FileHandle;
use Cwd;
use SOM::myutils;

#===========================================================#
sub new
{
	my ( $pkg, $mes ) = @_;
	
		my %options =
		(
			# -h	# html switch
			'html' => 0,
			
			# -m"Mexico"	# Made in "Mexico" switch
			'madein' => '',
			
			# -d 	# Debug switch1
			'debug' => 0,
			
			# -i # Debug - show image information
			'imageshow' => 0,
			
			# -s # Secondary Process Analysis and Report
			'secondary' => 0,
			
			# -c # Turn off Quark clip paths
			'clip' => 0,
			
			# -t # Turn off Quark template
			'template' => 0,
		
		);
	
	# Analyze switch information
# logprint "prog name: $0\n";
	my ( $progpath, $progname, $switches ) = 
    $0 =~ /(.+)\/(runprog(.*?).pl)/;
    
    $progpath = getcwd();
    $progname = $0;
    $switches = "";
    
    #			$0 =~ /(.+)\/(RatioCompiler(.*?).app)/;
	logprint "Getopt path: $progpath\nCommand line: $progname\n" if $mes;
	# $0 contains the program name, plus switches.
#	my @sinfo = split /-/, $switches;
	# logprint "Switches: \n";
#	my $showhelp = 0; # Only show help one time
#	foreach ( @sinfo )
#	{
		# logprint "|$_|; " if ( $_ );
			# Skip array entry with ''
#		next unless ( $_ );

			# Go through each of the possible
			# switches - unrecognized switches
			# are ignored
		$_ = $switches;		
		SWITCH:
		{
			/\s-h/ && do
			{
				# logprint "Found HTML switch\n";
				$options{ 'html' } = 1;
				# last SWITCH;
			};
			/\s-d/ && do
			{
				# logprint "Found Debug switch\n";
				$options{ 'debug' } = 1;
				# last SWITCH;
			};
			/\s-m"(.+?)"/ && do
			{
				# logprint "Found Made in switch\n";
				# my ( $madeinplace ) = /"(.+)"/;
				# logprint "Found Made in switch - place: $madeinplace\n";
				$options{ 'madein' } = $1;
				# last SWITCH;
			};
			/\s-i/ && do
			{
				# logprint "Found image show switch\n";
				$options{ 'imageshow' } = 1;
				# last SWITCH;
			};		
			/\s-s/ && do
			{
				# logprint "Found secondary process switch\n";
				$options{ 'secondary' } = 1;
				# last SWITCH;
			};		
			/\s-si/ && do
			{
				# logprint "Found secondary process switch\n";
				# With the 'si' option, do not delete temp files
				$options{ 'secondary' } = 2;
				# last SWITCH;
			};	
			/\s-c/ && do
			{
				# logprint "Found Quark clip switch\n";
				$options{ 'clip' } = 1;
				# last SWITCH;
			};
			/\s-t/ && do
			{
				# logprint "Found Quark template switch\n";
				$options{ 'template' } = 1;
				# last SWITCH;
			};
			/\s-\?/ && do
			{
				# logprint "Found help switch\n";
				gethelp( ) if $mes;
				# last SWITCH;
			};
		
		}
#	}
#	logprint "\n";
	bless \%options, $pkg;
	return \%options;
}
#===========================================================#
sub gethtml
{
	my ( $pkg ) = @_;
	return $pkg->{ 'html' };
}
#===========================================================#
sub getimageshow
{
	my ( $pkg ) = @_;
	return $pkg->{ 'imageshow' };
}
#===========================================================#
sub getmadeincountry
{
	my ( $pkg ) = @_;
	return $pkg->{ 'madein' };
}
#===========================================================#
sub getdebug
{
	my ( $pkg ) = @_;
	return $pkg->{ 'debug' };
}
#===========================================================#
sub getsecondaryprocess
{
	my ( $pkg ) = @_;
	return $pkg->{ 'secondary' };
}
#===========================================================#
sub getquarkclip
{
	my ( $pkg ) = @_;
	return $pkg->{ 'clip' };
}
#===========================================================#
sub gethktemplate
{
	my ( $pkg ) = @_;
	return $pkg->{ 'template' };
}
#===========================================================#
# Print help information for switches.
# RIPSAW -h -m"Mexico" -d -?
sub gethelp
{
	logprint
<<"EOS"
--Option switch usage: RIPSAW -h -m"Mexico" -d -?
Only one switch after each dash
Switch -h: Output html report
Switch -d: Output debug information
Switch -i: Output image diagnostic information
Switch -m"COUNTRY": Exchange "MADE IN U.S.A." with "MADE IN COUNTRY"
Switch -s: Run Secondary Process Analysis and Generate Report
Switch -si: Run Secondary Process Analysis and Generate Report - Don't delete temp files.
Switch -c: Disable Quark clip paths
Switch -t: Turn off Hallmark template
Switch -?: Output this help message
EOS
;
}
#===========================================================#
1;


