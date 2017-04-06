package SOM::myutils;

# Copyright © 2000-2005 Systems of Merritt, Inc.
# Written by Frank Braswell for Hallmark Cards
# October 2000
# November 2004 2.0 

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw( dumphash memreport memreportstr mbytes 
							timeofday timeofday_datetime logname loghandle logfilename
							openlog closelog logprint logprintf
							envincdump hrminsec distilleractive
							commas scommas dumphash1 dumphashalpha 
							setMactypecreator getMactypecreator );
# @EXPORT_OK = qw(&print);

use strict;
use FileHandle;
use Cwd;
# use Mac::AppleScript qw( RunAppleScript );

my $loghandle = 0; # Global loghandle.
my $logfilename = ''; # Global log file name.
openlog( ); # Open logfile for writing.

# print "loading myutils.pm\n";
sub logprint;
sub logprintf;
sub SOMhrminsec;
	# Trap fatal error messages and put them in the log.
$SIG{__DIE__} = \&trapdie;
#===========================================================#
sub trapdie
{
	my ( $sig ) = @_; # Grab the signal information.
		# Don't display junk messages which are trapped in other
		# modules and wouldn't be displayed otherwise.
	if ( $sig !~ /File ':AutoLoader.pm'; Line 88/ 
		&& $sig !~ /Data:Dumper.pm'; Line 19/
		&& $sig !~ /Exporter.pm'; Line 0/
	)
	{ logprint "FATAL ERROR MESSAGE! ";
		logprint $sig;
	}
	return;
} # end sub trapwarn
#===========================================================#
	# Trap warning messages and put them in the log.
$SIG{__WARN__} = \&trapwarn;
#===========================================================#
sub trapwarn
{
	my ( $sig ) = @_; # Grab the signal information.
	logprint "WARNING MESSAGE! ";
	logprint $sig;
	return;
} # end sub trapwarn
#===========================================================#
# Print results in min & seconds. Argument is in seconds.
sub hrminsec
{
	my ( $s ) = @_;
	# Catch 0
	return "0 seconds" unless ( $s );
	my $secp = $s % 60; # Printable seconds
	my $min = int ( $s / 60 ); # Number minutes
	my $minp = $min % 60; # Printable minutes
	my $hr = int ( $min / 60 ); # Number of hours

	return join '',( $hr>1 ? "$hr hours " : '', $hr==1 ? "$hr hour " : '',
	$minp != 0 ? "$minp min " : '', 
	$secp != 0 ? "$secp sec" : '', $s >=60 ? " or $s seconds" : '');
	
	return $hr ? "$hr hours " : '', $minp != 0 ? "$minp min " : '', 
			$secp != 0 ? "$secp sec" : '', $s >=60 ? " or $s seconds" : '';
} # end sub hrminsec
#===========================================================#
sub dumphash
{
	my ( $hash ) = @_;
	my ( $k, $h );
	foreach $k ( sort {$a <=> $b;} keys %$hash )
	{	logprint "  key: $k, value $hash->{$k}\n";
	}
} # end sub dumphash
#===========================================================#
sub dumphashalpha
{
	my ( $hash ) = @_;
	my ( $k, $h );
	foreach $k ( sort {$a cmp $b;} keys %$hash )
	{	logprint "  key: $k, value $hash->{$k}\n";
	}
} # end sub dumphash
#===========================================================#
# Turn off strict in order to use $sortfunc symbolic reference
sub dumphash1
{
	my ( $hash ) = @_;
	my @tg = %$hash;
	my $sortfunc = $tg[0] =~ /\d/?'NUMERIC':'ASCIIbetic';
	no strict 'refs';
	foreach  ( sort  $sortfunc keys  %$hash )
	{	logprint "  key: $_, value $hash->{$_}\n";
	}
} # end sub dumphash

#===========================================================#
sub NUMERIC
{ $a <=> $b } 
#===========================================================#
sub ASCIIbetic
{ $a cmp $b }
#===========================================================#
sub memreport
{
	my ( $v, $r ) = ( split /\s+/, `ps -uxww -p $$` )[ 15, 16 ];
	logprintf("Real Memory: %0.6f Mb ",mbytes( $r * 1024 ));
	logprintf("Virtual Memory: %0.6f Mb \n",mbytes( $v * 1024 ));
}
#===========================================================#
# This proc prints memory information along with a string
# which is passed by the calling program.
sub memreportstr
{
	my ( $s ) = @_;
	my ( $v, $r ) = ( split /\s+/, `ps -uxww -p $$` )[ 15, 16 ];
	logprintf("Real Memory: %0.6f Mb ",mbytes( $r * 1024 ));
	logprintf("Virtual Memory: %0.6f Mb",mbytes( $v * 1024 ));
	logprint "== $s\n";
}
#===========================================================#
# Print results in Megabytes
sub mbytes { $_[0] / (1024**2) }

#===========================================================#
# Format number with commas
sub commas_old
{
	my ( $n ) = @_;
	my $len = length $n;
	if ( $len % 3 > 0 )
	{ logprint substr $n, -$len, $len % 3;
		logprint ',' if ( $len > 3 );
	}
	for ( my $i = $len - ( $len % 3 );  $i > 0; $i -= 3 )
	{ logprint substr $n, -$i, 3;
		logprint ',' if ( $i > 3 );
	}
}
#===========================================================#
# Format number with commas
sub commas
{
	( $_ ) = @_;
	my ( $int, $per,  $frac );
	unless ( ( $int, $per, $frac ) = /(\d+?)(\.)(\d*)/ )
	{
		$int = $_;
		$frac = '';
		$per = '';
	}
	
	1 while $int =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/;
	logprint $int.$per.$frac;
	
#	( $_ ) = @_;
#	1 while s/(\d)(\d\d\d)(?!\d)/$1,$2/;
#	logprint $_;
}
#===========================================================#
# Format number with commas
# return a string
sub scommas
{
	( $_ ) = @_;
	my ( $int, $per,  $frac );
	unless ( ( $int, $per, $frac ) = /(\d+?)(\.)(\d*)/ )
	{
		$int = $_;
		$frac = '';
		$per = '';
	}
	
	1 while $int =~ s/(\d)(\d\d\d)(?!\d)/$1,$2/;
	return $int.$per.$frac;
	
#	( $_ ) = @_;
#	1 while s/(\d)(\d\d\d)(?!\d)/$1,$2/;
#	return $_;
}
#===========================================================#
# Format number with commas
# return a string
sub scommas_old
{
	my ( $n ) = @_;
	my @s;
	my $len = length $n;
	if ( $len % 3 > 0 )
	{ push @s, substr $n, -$len, $len % 3;
		push @s, ',' if ( $len > 3 );
	}
	for ( my $i = $len - ( $len % 3 );  $i > 0; $i -= 3 )
	{ push @s, substr $n, -$i, 3;
		push @s, ',' if ( $i > 3 );
	}
	return join '', @s;
}
#===========================================================#
# This procedure returns the date and time in the format:
# 13:09:34 Tuesday August 11, 2000
sub timeofday
{
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $isdst) 
		= localtime( time );
	my $weekday = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
		[ $wday ];
		
	my $month = ( 'January','February','March','April',
				 'May', 'June', 'July', 'August', 'September',
				 'October', 'November', 'December' )
				 [ $mon ];
	my $trueyear = $year + 1900;
	my $timestr = sprintf '%02d:%02d:%02d %s, %s %d, %d',	$hour,$min,$sec,$weekday, $month, $mday, $trueyear;
	return $timestr;
	#return "$hour:$min:$sec $weekday, $month $mday, $trueyear";
} # end sub timeofday
#===========================================================#
# This procedure returns the date and time in the format:
# 13:09:34 Tuesday August 11, 2000
sub timeofday_datetime
{
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $isdst) 
		= localtime( time );
	my $weekday = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday')
		[ $wday ];
		
	my $month = ( 'January','February','March','April',
				 'May', 'June', 'July', 'August', 'September',
				 'October', 'November', 'December' )
				 [ $mon ];
	my $trueyear = $year + 1900;
	my $timestr = sprintf '%02d:%02d:%02d',	$hour,$min,$sec;
	my $datestr = sprintf '%s/%d/%d', $mon + 1, $mday, $trueyear;
	return ( $datestr, $timestr );
	#return "$hour:$min:$sec $weekday, $month $mday, $trueyear";
} # end sub timeofday-datetime
#===========================================================#
# This procedure generates a name for the log file
# using time of day information.
sub logname
{
		# If the $logfilename is already defined use it.
		# The first time logname is called, it will define
		# the logfilename.
	# print "log file name: $logfilename\n";
	return $logfilename if( $logfilename ne '' );
	
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$isdst) 
		= localtime(time);
	my $weekday = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
		[ $wday ];
		
	my @months = qw/jan feb mar apr may jun jul aug sep oct nov dec/;
	my $month = $months[ $mon ];
	my $trueyear = $year + 1900;
	# my $hr = ('00','01','02','03','04','05','06','07','08','09','10','11','12','13','14',
	# 					'15','16','17','18','19','20','21','22','23','24')[$hour];
	# my $timestr = sprintf '%02d-%02d-%02d',$hour,$min,$sec;
	my $timestr = sprintf '%s-%02d-%4d-%02d-%02d-%02d.log',$month, $mday, $trueyear,$hour,$min,$sec;
	return $logfilename = $timestr;
	return $logfilename = "$month-$mday-$trueyear-$timestr.log";
	# return $logfilename = "$month-$mday-$trueyear-$hr-$min-$sec.log";
	return $logfilename;
} # end sub logname
#===========================================================#
sub openlog
{
	# Place the log file in a "logfiles" folder.
	# If the folder doesn't exist, create it.
	my $logfolder = 'logfiles';
    #	print "working directory: ", getcwd(), "\n";
    #    print "prog name: $0\n";
	my ( $progpath, $progname, $y ) = 
			$0 =~ /(.+)\/(runprog(.*?).pl)/;
    #    $progpath = getcwd();
	$logfolder = $progpath.'/SOM/logfiles';
    #	print "log folder: ", $logfolder, "\n";
	unless ( -d $logfolder )
	{ mkdir( $logfolder, 0755 ); # Create folder.
	}
	
	my $ti = "$logfolder/".logname();
	$loghandle = new FileHandle $ti, 'w+'; # Create or open for append.
	# if ( not defined $loghandle )
	unless ( defined $loghandle )
	{ print "Can't open file: $ti\n";
		return;
	}
		# Flush data to the file immediately. If RIPSAW crashes, the data
		# will already be written to the file.
	autoflush $loghandle 1;
	setMactypecreator( $ti , 'TEXT', 'R*ch' ); # Make the status file a BBedit file
#	MacPerl::SetFileInfo( 'R*ch','TEXT',$ti);
} # sub openlog
#===========================================================#
sub closelog
{
	undef $loghandle;
}
#===========================================================#

# logprintf prints messages to both the perl log and a log file.
sub logprintf
{
	my $fh = $loghandle; # file handle
	unless ( defined $fh )
	{ print "fh not defined\n";
		return;
	}	
	printf $fh @_;
	printf STDOUT @_;
} # end sub logprintf
#===========================================================#

# logprint prints messages to both the perl log and a log file.
sub logprint
{
	my $fh = $loghandle; # file handle
	unless ( defined $fh )
	{ print "fh not defined\n";
		return;
	}
	print $fh @_;
	print STDOUT @_;	
} # end sub logprint
#===========================================================#
# Print some diagnostic information on internal Perl
# module search paths and variables.
sub envincdump
{
	# Diagnostic info begin
	print "Dump internal paths and variables.\n";
    print "Name of file containing Perl script: ",$0,"\n";
	print "INC array:\n";
	print map "$_\n",@INC;
	print "INC hash:\n";
	foreach my $h (sort keys %INC)
	{ print "$h => $INC{$h}\n";
	}
	print "ENV hash:\n";
	foreach my $h (sort keys %ENV)
	{ print "$h => $ENV{$h}\n";
	}
	# Diagnostic info end
} # end sub envincdump
#===========================================================# 
sub setMactypecreator
{
	# Pass the file name, type and creator
	my ( $fnu, $t, $c ) = @_;
	# Convert from UNIX bullet to Mac bullet for
		# the Distiller Applescript.
		# Change all * chars in the path
	# $fn =~ s/\342\200\242/•/g; # Convert UNIX chars to • Mac bullet
	# $fn =~ s/:/\//g; # Convert any UNIX : to / Mac
	# $fn =~ s/\//:/g; # Convert all UNIX / to Mac :
	my $fn = filenameUnixtoMac( $fnu );
		# 1-12-06 These next two statements set the type and creator
		# strings to a null string in the event they are undefined
	$t = '' unless $t;
	$c = '' unless $c;
	$t =~ s/"//g; # Get rid of quotes: "EPSF"
	$c =~ s/"//g; # Get rid of quotes: "XPR3"
	my $settc = 
<<END_SCRIPT
tell application "Finder"
set f to \"$fn\"
set file type of file f to \"$t\"
set creator type of file f to \"$c\"
end tell
END_SCRIPT
;
# logprint $settc;
# return RunAppleScript( $settc )
}
#===========================================================# 
sub getMactypecreator
{
	my $fnu = shift;
	# Convert from UNIX bullet to Mac bullet for
		# the Distiller Applescript.
		# Change all * chars in the path
	# $fn =~ s/\342\200\242/•/g;
	# $fn =~ s/\//:/g;
	my $fn = filenameUnixtoMac( $fnu );
	my $gettype = 
<<END_SCRIPT
tell application "Finder"
set f to \"$fn\"
get file type of file f
end tell
END_SCRIPT
;
	my $getcreator = 
<<END_SCRIPT
tell application "Finder"
set f to \"$fn\"
get creator type of file f
end tell
END_SCRIPT
;
	# Return list
# return ( RunAppleScript( $gettype ), RunAppleScript( $getcreator ) );
}
#===========================================================#
# Convert a Unix file name to a Mac file name
# This requires converting the slash delimiter to a 
# colon delimeter. Also, any colons in the unix directories
# need to be converted to slashes, plus we need to handle the
# • bullet character.
sub filenameUnixtoMac
{
	my $ufn = shift; # Get the unix file name
	my @fa = split /\//, $ufn;
#	map { logprint "_ $_ - " } @fa;
#	logprint "fa[1]: ", $fa[ 1 ];
	if ( $fa[ 1 ] =~ /Volumes/ )
	{
		shift @fa; shift @fa;
	}
	# Change UNIX : to / for Mac within directories
	# Also change bullet char
	map { s/:/\//g; s/\342\200\242/•/g } @fa;
	# logprint "-- Unix fn: $ufn\n-- Mac fn: ", join ':', @fa, "\n";	
	return join ':', @fa;
}
#===========================================================#
1; # end package myutils
