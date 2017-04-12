package SOM::SOMcontrol;

# Copyright (c) 2007 Systems of Merritt, Inc.
# Written by Frank Braswell for Berry Plastics
# Update 4-30-10 remove reference to AppleScript
# Updated March/April 2017

# This package is responsible for parsing the input files and
# building data structures with the data
 
require Exporter;
@ISA = qw(Exporter);
#@EXPORT_OK = qw( initstuff processjob OpenDocuments keypress);
@EXPORT_OK = qw( initstuff processjob );
use strict;
use FileHandle;
use Cwd;
use SOM::myutils;
use SOM::Stopwatch;
use SOM::getopt;
use SOM::SOMtables;
# use Mac::AppleScript qw( RunAppleScript );

my $_conversion = 'conversion';
my $_ratio = 'ratio';
my $_measurement = 'measurement';
my $_parameter = 'parameter';

# print "load SOMcontrol.pm\n"; # DEBUG

my $ratiocompilerver = '2.0';

# DEBUG Input record separator affects how Font & Color EPS
# is parsed
$/ = "\r"; # input record separator
$| = 1; # flush after each write


#    print "prog name: $0\n";
#	my ( $progpath, $progname, $y ) = 
#			$0 =~ /(.+)\/(runprog(.*?).pl)/;
#            $0 =~ /(.+)\/(RatioCompiler(.*?).app)/;
#	print "Program path: $progpath\nCommand line: $progname\n";

openlog(); # Open logfile for writing.
logprint "\n------Berry Plastics RatioCompiler Version $ratiocompilerver \n";
my ( $d, $t ) = timeofday_datetime( );
logprint "Date: $d, Time: $t\n";
# logprint "prog name: $0\n";
# my $switches = new SOM::getopt( 'message' );
# logprint "HTML switch: ", $switches->gethtml( ), "\n";
# logprint "Made in: ", $switches->getmadeincountry( ), "\n";
# logprint "Debug: ", $switches->getdebug( ), "\n";
# logprint "Image show debug info: ", $switches->getimageshow( ), "\n";

#    logprint "prog name: $0\n";
	my ( $progpath, $progname, $y ) = 
			$0 =~ /(.+)\/(runprog(.*?).pl)/;
    logprint "Program path: $progpath\nCommand line: $progname\n";
#    chdir($progpath);
    $progpath = getcwd();
#            $0 =~ /(.+)\/(RatioCompiler(.*?).app)/;
	logprint "cwd Program path: $progpath\nCommand line: $progname\n";
	# $0 contains the program name, plus switches.
	my $fc = "$progpath/FMB Fonts & Colors.txt";
	# logprint "Fonts & colors file: $fc\n";
    
#   my $fch1;
#   $fch1 = FileHandle->new;
##    $fch1->open ("> $fc") || die "Can't open FMB Fonts & Colors file\n";
#    $fch1->open (">/FMBFontsColors") || die "Can't open FMB Fonts & Colors file\n";
#    
#    print $fch1 "test text\n";
#    die "Stop Here!";

#===========================================================#
	# Process Colors Global Variables
my %processcolors = 
(
	'Cyan' => "1 0 0 0",
	'Magenta' => "0 1 0 0",
	'Yellow' => "0 0 1 0",
	'Black' => "0 0 0 1",
);
	# This is a list of all the current parameters
	# It will be used to check to see if they are
	# all present in the input file.
my %parameterlist =
(
	'Ratio Chart Top Offset (inches)' => '',
	'Ratio Chart Width (inches)' => '',
	'Ratio Chart Height (inches)' => '',
	'Measurement Chart Width (inches)' => '',
	'Measurement Chart Height (inches)' => '',
	'Measurement Chart Location (on Right or on Left)' => '',
	'Column Space (inches)' => '',
	'Vertical Line Weight Outside (points)' => '',
	'Vertical Line Weight Inside (points)' => '',
	'Vertical Line Color Outside' => '',
	'Vertical Line Color Inside' => '',
	'Ratio Header Height (inches)' => '',
	'Ratio Header Font' => '',
	'Ratio Header Font Color' => '',
	'Ratio Header Font Size (points)' => '',
	'Ratio Number Location (Above or Below)' => '',
	'Ratio Column Font' => '',
	'Ratio Column Font Color' => '',
	'Ratio Column Font Size (points)' => '',
	'Header Horizontal Line Weight (points)' => '',
	'Header Horizontal Line Color' => '',
	'Horizontal Line Weight (points)' => '',
	'Horizontal Line Color' => '',
	'Measurement Chart Font' => '',
	'Measurement Chart Font Color' => '',
	'Measurement Chart Font Size (points)' => '',
	'Operator Name' => '',
	'Customer Name' => '',
	'Container Part Number' => '',
	'Job Number' => '',
);
#===========================================================#	
	# colors
    
    # Look for a file with /Fonts|Colors/i in the name at the
    # location $dh, which is determined below
    
    # The fonts and colors are added into the final EPS file
    
#		%%CMYKCustomColor: 0 0 0 0.2400 (PANTONE Cool Gray 4 C)
#		%%+ 0 1 0.8100 0.0400 (PANTONE 186 C)
#		%%+ 1 0.5700 0 0.0200 (Berry Blue)
#		%%+ 0 0 0.5300 0 (substrate)

#		%%DocumentFonts: CenturySchoolbook
#		%%+ Times-Roman
#		%%+ LucidaSans
#		%%+ Helvetica
#		%%+ AGaramond-Regular
#		%%+ Courier
#		%%+ Myriad-Roman
	
	my $fch; # file handle
	my %fonts; # fonts hash
	my %colors; # colors hash
	my $cname; # color name
	my $cvals; # color values
	my $fname; # font name
	my $fvals; # font values - same as name - allows hash names to be sorted easily
	my $foundfont = 0; # font comments found?
	
		my $dh; # directory handle
	opendir $dh, $progpath || die "Can't open program folder\n";
		# List each file in the folder
        # Look for my "$progpath/Fonts & Colors.txt";
        # Determine fonts, process colors and spot colors
	foreach ( readdir $dh )
	{
#		logprint "read directory file: $_\n";
        # Example file names
        # Berry Fonts.eps
        # Berry Colors.eps
        # Paint Spot Fonts & Colors.eps
		if ( /Fonts|Colors/i )
		{ 
			# logprint "found colors file: $_\n";
			$fc = "$progpath/$_";
			open $fch, $fc || die "Can't open Fonts & Colors file\n";
			logprint "**Fonts & Colors file: $_\n";
            local $/ = "\n"; # input record separator for this block only - EPS file
			while ( <$fch> ) # read in lines of file
			{			
#                chomp; # no need to chomp
#                logprint "-line: $_";
                last if /%%EndComments/i;
                #		%%DocumentFonts: CenturySchoolbook
                #		%%+ Times-Roman
                if ( $foundfont || /documentfonts/i )
				{
					unless ( /documentfonts/i || /%%\+/ )
					{
						$foundfont = 0;
						next;
					}
					( $fname ) = /[\+:] (.+)$/;
					chomp ( $fname );
					$fonts{ $fname } = $fname if $fname;
					# logprint "Found document font name: $fname";
					$foundfont = 1;
					next;
				}
				
                #		%%+ 1 0.5700 0 0.0200 (Berry Blue)
				if ( ( $cvals, $cname ) = /[\+:] (\d.+)\s\((.+)\)/ )
				{
					# logprint "Found color name: $cname; values: $cvals\n" if $cvals;
					$colors{ $cname } = $cvals if $cvals;
				}
				# logprint "-line: $_";
				# last if /%%endcomments/i;
			}
			# logprint "**End of Fonts & Colors file:\n";
	
			} # if ( /Fonts|Colors/i )
	} # foreach ( readdir $dh )
	closedir $dh;
	
	foreach ( sort keys %fonts )
	{
		logprint "-Font: $_\n";
	} 
	foreach ( sort keys %processcolors ) # predefined CMYK above
	{
		logprint "=Process Color: $_\n";
	}
	foreach ( sort keys %colors )
	{
		logprint "=Spot Color: $_\n";
	}
	# The following closures control access to 
	# important control variables.
# {	# begin closure
	
#	die "HALT PROGRAM!!!";
# } # end closure
#===========================================================#
# This procedure is called from runprog.pl to set up any initial
# data or procedures.
sub initstuff
{
	# Establish path to distiller application
# distillerpath();

# Diagnostic procedure. Enable if needed.
envincdump( ) if (0);
} # end sub initstuff
#===========================================================#
# This function is called from runprog.pl. It is responsible for 
# coordinating the main processing work of this software package.
# It is called after initstuff above.
sub processjob
{	
	my $result;
	my @convobj;
    my $fh;
	$result = 'status ok';
    # @ARGV contains the command line arguments,
    # which are the names of the 3 input files
	foreach my $fin ( @ARGV )
	{
		logprint "Input file: $fin\n";
        #		my $fh;
        #        $fh = ""; # init handle
		if (open $fh, $fin)
        { logprint "";
        } else
        { logprint "File didn't open: $fin\n";
        }
		# parsetables figures out what kind of input
        # file we are deling with and processes it.
		push @convobj, ( parsetables( $fh, $fin ) );
	
	} # foreach my $fin ( @ARGV )
	buildeps( \@convobj );
	return $result;
} # end sub processjob
#===========================================================#
#				T41032TP2																			
#
#				Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches
#				50		4.138			118.5	3.7444		202.5	3.2827		295.7	2.766			390.3	2.271			499		1.71			609		1.1745
#				55		4.122			120		3.733			203		3.280			297		2.7600		392		2.2633		500		1.705			610		1.17

# Parse conversion table - see example above
sub parsetables
{
	my $fh = shift; # Get file handle
	my $fin = shift; # Get file name
#    my @tmp = split '/', $fin;
#    my $fnamein =  pop @tmp;
    my $fnamein = pop [split '/', $fin]; # force array context
	my $prevloc; # location of prev line in file - starts at 0
	my $partnum;
	my $charttype = ''; # conversion, ratio, measurement or parameter tables
	my @linearr;
	my $col;
	my $linenum = -1; # track line number
	my @coltemplate; # template for columns
	my %convhash; # conversion hash of grams and inches
	my @tableobjects;

	while ( <$fh> ) # Go through each line of the file
	{
		chomp; # remove line endings
		$linenum++; # increment line number
		@linearr = split "\t"; # split line on whitespace
		
#		next if @linearr == 0; # discard lines with no information
		
		if ( @linearr == 0 ) 
		{
			# tell gets current file location
            $prevloc = tell; # Set previous location for next loop
			next;
		}
		
		# Usually the first line will contain a part number which
		# indicates what kind of cup will be used. It is the only
		# thing on the line.
#			T41032TP2	
		
		# part number is only thing on line - 
		# within first few (5) lines of file
		if ( @linearr == 1 && $linenum < 5 )
		{
			$partnum = shift @linearr;
			# logprint "line: $linenum - Part Number: $partnum\n";
            # tell returns the current file position
			$prevloc = tell; # Set previous location for next loop
			next;
		}
		
		# Determine the kind of tables 
		# 1. Conversion Table
		
#				Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches		Grams	Inches
#				50		4.138			118.5	3.7444		202.5	3.2827		295.7	2.766			390.3	2.271			499		1.71			609		1.1745
#				55		4.122			120		3.733			203		3.280			297		2.7600		392		2.2633		500		1.705			610		1.17
		
        # Found in a separate file
        # Look for Grams keyword
		if ( $linearr[ 0 ] =~ /grams/i && $linenum < 5 )
		{
			$charttype = 'conversion';
			# logprint "line: $linenum - Found Conversion Table Header info: $_\n";
		}
		
		
		# Found in same file as measurement tables
        # 2. Ratio Tables
		
#					2			1			10%
#			1		60		90		96
#			2		120		180		192
#			3		180		270		288
#			4		240		360		384
#			5		300		450		480
#			6		360		540		576
#			7		420		630		672		

		# Step through the line array, looking for data
        for ( my $i = 0; $i < $#linearr - 1; $i++ )
		{
			# Look for a ratio table
            # Nothing in first location, number in second location
            if ( not $linearr[ $i ] and $linearr[ $i + 1 ] =~ /\d/ )
			{
				$charttype = 'ratio';
				# logprint "----values found: ", $linearr[ $i ], " and ", $linearr[ $i + 1 ], "\n";
				# logprint "--found ratio on line: $_\n";
			}
		} # for ( my $i = 0; $i < $#linearr - 1; $i++ )
		
		# Found in same file as ratio tables
        # 3. Measurement Tables
		
#				Parts				Ounces					mL
#				1		72			2	59.1				50
#				2		144			4	118.3				100
#				3		216			6	177.4				150
#				4		288			8	236.6				200
#				5		360			10	295.7				250
#				6		432			12	354.8				300
#				7		504			14	414.0				350
#				8		576			16	473.1				400
#				9		648			18	532.3				450
#				10	    720			20	591.4				500
#									22	650.5				550
#									24	709.7				600
#									26	768.8				650
#															700
#															750		
        # Step through the line array, looking for data
		for ( my $i = 0; $i < $#linearr; $i++ )
		{
			# Look for a measurement table header
            # look for "ounces", "parts" or "ml"
            if ( 	$linearr[ $i ] =~ /ounces/i || 
						$linearr[ $i ] =~ /parts/i ||
						$linearr[ $i ] =~ /ml/i )
			{
				$charttype = 'measurement';
				# logprint "--found measurement on line: $_\n";
			}
		} # for ( my $i = 0; $i < $#linearr; $i++ )
					
		
		# In a separate parameter file
        # 4. Parameter Table

#				# comment line at top
#				Kim					Operator Name
#				Hyman				Customer Name
#				T41032TP		Container Part Number
#			    H559918_9108	Job Number	
#				0.25				Ratio Chart Top Offset (inches)
#				0.2					Ratio Chart Width (inches)
#				4						Ratio Chart Height (inches)
#				0.5					Measurement Chart Width (inches)
#				4						Measurement Chart Height (inches)
#				Left				Measurement Chart Location (on Right or on Left)
#				0.2					Column Space (inches)
#				2						Vertical Line Weight Outside (points)
#				1						Vertical Line Weight Inside (points)
#				Black				Vertical Line Color Outside
#				Black				Vertical Line Color Inside
#				# comment over Ratio Header Height	
#				0.25				Ratio Header Height (inches)
#				Helvetica		Ratio Header Font
#				Black				Ratio Header Font Color
#				8	Ratio 		Header Font Size (points)
#				Below				Ratio Number Location (Above or Below)
#				Helvetica		Ratio Column Font
#				Black				Ratio Column Font Color
#				8						Ratio Column Font Size (points)
#				# New Header horizontal line parameters	
#				0.5					Header Horizontal Line Weight (points)
#				Magenta			Header Horizontal Line Color
#				# Ratio chart horizontal line parameters	
#				1						Horizontal Line Weight (points)
#				Black				Horizontal Line Color
#				Helvetica		Measurement Chart Font
#				Black				Measurement Chart Font Color
#				10					Measurement Chart Font Size (points)
#				# comment at end	


		# Look for chart key words
        # See if you can find "Ratio Chart Width" within the first 5 lines
		if ( $linearr[ 1 ] =~ /Ratio Chart Width/i && $linenum < 5 ) 
		{
			$charttype = 'parameter';
			# logprint "line: $linenum - Found Conversion Table Header info: $_\n";
		}
	
			# Determine what type of tables
		# $_ = $charttype;
		# Each of the parsing procedures below returns one or more
		# table objects. The objects are collected in the @tableobjects
		# array.
		CASE:
		{
			$charttype =~ /$_conversion/		&& do
													{
														logprint "Parse conversion table\n";
														push @tableobjects, ( parseconversiontable( $fh, $fin ) );
                                                        $_conversion = 'not found again';
														last CASE;
													};
			$charttype =~ /$_ratio/		&& do
													{
														logprint "Parse ratio tables\n";
														push @tableobjects, ( parseratiotables( $fh, $fin ) );
                                                        $_ratio = 'not found again';
														last CASE;
													};
			$charttype =~ /$_measurement/		&& do
													{
														logprint "Parse measurement tables\n";
														# push @tableobjects, ( parsemeasurementtables( $fh, $fin ) );
														push @tableobjects, ( parseratiotables( $fh, $fin ) );
                                                        $_measurement = 'not found again';
														last CASE;
													};
			$charttype =~ /$_parameter/		&& do
													{
														logprint "Parse parameter table\n";
														push @tableobjects, ( parseparametertable( $fh, $fin ) );
                                                        $_parameter = 'not found again';
														last CASE;
													};
													
#			logprint "No table found in \"$fnamein\" at $linenum\n";
            logprint "Looking for table in \"$fnamein\" at line $linenum\n";
		} # end CASE
		
		$prevloc = tell; # Set previous location for next loop
	} # while ( <$fh> )
	
#		logprint "**(parsetables) Name of all table objects:\n";
#	foreach ( @tableobjects )
#	{
#		logprint $_->gettablename( ), ": ", $_->getfilename, "\n";
#	}
	
	return @tableobjects;
} # sub parsetables
#===========================================================#
		
#					2			1			10%
#			1		60		90		96
#			2		120		180		192
#			3		180		270		288
#			4		240		360		384
#			5		300		450		480
#			6		360		540		576
#			7		420		630		672		

sub parseratiotables
{
	my $fh = shift;
	my $fin = shift; # Get file name
	seek $fh, 0, 0; # Reset to beginning of file
	my @linearr;
	my $col;
	my $linenum = -1; # track line number
	my $lookforheader = 1;
	my $firstcol = 1; # look for first col of table
	my $tablenum = -1; # Create table names
	my @tableranges; # Track table names
		# push the beginning and end index of each active table
		# pop off table that is finished
	my %tablehash; # store table objects
	
	# Locate the beginning and end of table indexes in a row.
	# Slice operations are used to extract column info from each row.
	my @sliceranges;
	my $foundindex;

    # read lines from ratio tables file
	while ( <$fh> )
	{
		chomp;
		$linenum++; # increment line number
		@linearr = split "\t"; # split line on whitespace
		
		### DEBUG ### logprint "lookforheader: $lookforheader; line: ";
		### DEBUG ### @linearr? map { logprint $_?"$_|":'*|' } @linearr: logprint 'blank line'; 
#		logprint "\n";
			# Discard lines with no information
			# Blank lines also indicate new tables
		if ( @linearr == 0 )
		{
			$lookforheader = 1; # Start looking for next table header
			# @sliceranges = ( ); # Init array
			# next;
		}
		
		if ( 1 or $lookforheader )
		{
				# Step through each element of the line looking for table information
			# for ( my $i = 0; $i <= $#linearr - 1; $i++ )
			for ( my $i = 0; $i < $#linearr; $i++ )
			{
					# If index is known in the @sliceranges array skip to next col
					$foundindex = 0;
					foreach ( @sliceranges )
					{
						if ( $_ - 1 == $i or $_ == $i )
						# if ( $_ == $i )
						{
								# Found index
								$foundindex = 1;
								last;
						}
					} # foreach ( @sliceranges )
					next if $foundindex;
				
				my $tmpind;
				if ( $i == 0 && $linearr[ $i ] =~ /ounces|parts|ml/i )
				{	$tmpind = $i - 1;
				} else
				{	$tmpind = $i;
				}
					# Measurement tables may be mixed in with ratio tables
				# if ( $linearr[ $i + 1 ] =~ /ounces|parts/i )
				if ( $linearr[ $tmpind + 1 ] =~ /ounces|parts/i )
					{
						### DEBUG ### logprint "++found measurement table: ", $linearr[ $i + 1 ], "++";
							# Ounces table is always 2 columns wide, right under the "ounces" label
							# The dummy entry is necessary so that the blank space after Ounces or Parts
							# won't be seen as the end of a table
						$linearr[ $tmpind + 2 ] = 'dummy';
						push @sliceranges, $tmpind + 1; # push beginning index
						push @sliceranges, $tmpind + 2; # push ending index
						$lookforheader = 0; # Turn off look for header until next blank column
						### DEBUG ### 
						# logprint ">>>>>Found Ounces or Parts Table", $tablenum, "<<<<<<";
						push @tableranges, ( $tmpind + 1, 'table'.(++$tablenum<=9?'0':'').$tablenum );
						next;
					}
					
					# $tmpind = $i - 1;
						# Measurement tables may be mixed in with ratio tables
				# if ( $linearr[ $i + 1 ] =~ /ml/i )
				if ( $linearr[ $tmpind + 1 ] =~ /ml/i )
					{
						### DEBUG ### logprint "++found ml measurement table: ", $linearr[ $i + 1 ], "++";
							# ML table is always 1 columns wide, right under the "ounces" label
						push @sliceranges, $tmpind + 1; # push beginning index
						push @sliceranges, $tmpind + 1; # push ending index
						$lookforheader = 0; # Turn off look for header until next blank column
						#### DEBUG ### 
						# logprint ">>>>>Found ml Table", $tablenum, "<<<<<<";
						push @tableranges, ( $tmpind + 1, 'table'.(++$tablenum<=9?'0':'').$tablenum );
						next;
					}
					
						# ignore unknown text
					if ( $linearr[ $i ] =~ /^\D/ )
					{
						# logprint "**unknown text: ", $linearr[ $i ], "**";
						next;
					}					
				
					# logprint " col: $i; val: ", $linearr[ $i ], " - ";
					# Locate beginning of table or tables
					# First row of table will have a blank cell followed by a cell with a number
				if ( $firstcol and not $linearr[ $i ] and $linearr[ $i + 1 ] =~ /^\d/ )
				{
					# logprint "----first values found: ", $linearr[ $i ], " and ", $linearr[ $i + 1 ];
					push @sliceranges, $i; # push beginning index
					$firstcol = 0;
					# logprint "--found ratio on line: $_\n";
					$lookforheader = 0; # Turn off look for header until next blank column
					### DEBUG ### logprint ">>>>>Found Table", ++$tablenum, "<<<<<<";
					push @tableranges, ( $i, 'table'.(++$tablenum<=9?'0':'').$tablenum );
				}
				
					# Locate end of table or tables
					# The end will have a cell with a number followed by a blank cell
				if ( not $firstcol and $linearr[ $i ] =~ /^\d/ and not $linearr[ $i + 1 ] )
				{
					# logprint "----last values found: ", $linearr[ $i ], " and ", $linearr[ $i + 1 ];
					push @sliceranges, $i; # push ending index
					$firstcol = 1;
					# logprint "--found ratio on line: $_\n";
				}
				
					# Locate end of table or tables
					# The end can also have a cell with a number in the last cell
				if ( not $firstcol and $i + 1 == $#linearr and $linearr[ $i + 1 ] =~ /^\d/ )
				{
					# logprint "----last value found at eol: ", $linearr[ $i + 1 ];
					push @sliceranges, $i + 1; # push ending index
					$firstcol = 1; 
					# logprint "--found ratio on line: $_\n";
				}
			
			} # for ( my $i = 0; $i < $#linearr - 1; $i++ )	
			
			### DEBUG ### logprint "== header slicerange: ";
			### DEBUG ### map { logprint "$_|" } @sliceranges;
			### DEBUG ### logprint "== table tablerange: ";
			### DEBUG ### map { logprint "$_|" } @tableranges;
			### DEBUG ### logprint "\n";		
				
		} # if ( $lookforheader )

			# look for first col of table
			# Slice range entries always come in pairs.
			# A beginning ($firstcol = true) should always have an end
		unless ( $firstcol )
		{
			logprint "%% ERROR firstcol%%";
		}

			# First check for end of tables. If there is a blank
			# cell at the bottom the table is ended
#		logprint "== body slicerange before: ";
#		map { logprint "$_|" } @sliceranges;
		# logprint "\n";
			# The slice range entries come in pairs, the first
			# number is the beginning col of the table and the
			# second number is the end of the table (inc $i by 2 
			# checking the end of each table by starting $i at 1.
		my @tmpsr = ( );
		map { push @tmpsr, $_ } @sliceranges; # put @slicerangest in @tmpsr
		my @tmptr = ( );
		map { push @tmptr, $_ } @tableranges; # put @tableranges in @tmptr
		
		for ( my $i = 1; $i <= $#tmpsr; $i += 2 )
		{
			### DEBUG ### logprint "**tmpsr index: $i; tmpsr end: $#tmpsr**";
			
				# If nothing in the cell remove the table indices
			unless ( $linearr[ $tmpsr[ $i ] ] )
			{
					# Get rid of the table slice indices
				splice @sliceranges, $i - 1, 2; # Remove 2 elements
					# Get rid of table name
				splice @tableranges, $i - 1, 2; # Remove 2 elements
				$lookforheader = 1; 
				# logprint "val: *|";
			} else
			{
				# At this point, there is data for the table - 
				# at least one table row, perhaps more than one
				# logprint " val: ", $linearr[ $tmp[ $i ] ], '|';
				
				# If something in the cell, create object if nessary
				# and store row of data
					# slicerange contains the beginning and ending
					# index for data in the line belonging to a specific
					# table
				# slicerange: 6|9|0|3|
					# The table range contains the beginning index
					# and table name
				# tablerange: 6|table7|0|table8|
				# next unless $tableranges[ $i ];
				# Place a leading 0 in front of table numbers less than 10
				# $tableranges[ $i ] =~ s/table(\d)$/table0$1/;
				unless ( exists $tablehash{ $tmptr[ $i ] } )
				{ # If table name doesn't exist create new 
					# table object
					my $tableobj =
					new SOM::SOMtables( $tmptr[ $i ], $fin );			# add table name
															
					# logprint "==Table name method: ", $tableobj->gettablename( ), "\n";
															
					$tablehash{ $tableobj->gettablename( ) } = $tableobj;
				} # unless ( exists $tablehash{ $tableranges[ $i ] } )
				### DEBUG ### logprint "**add data tmp index: $i**";
				# Add row data
				$tablehash{ $tmptr[ $i ] } -> addtablerow
														( $tmptr[ $i ],			# table name
															$tmpsr[ $i -1 ],	# begin index
															$tmpsr[ $i ],			# end index
															@linearr	);		
				
				
			} # for ( my $i = 1; $i <= $#tmp; $i += 2 )
			
		} # for ( my $i = 1; $i <= $#sliceranges; $i += 2 )		

	} # while ( <$fh> )
	
	# logprint "### Dump tablehash ###\n";
	foreach ( sort keys %tablehash )
	{
		# logprint "table name: $_\n";
		$tablehash{ $_ }->tableprint( );
	}
	
	return values %tablehash;
} # sub parseratiotables
#===========================================================#
#				5						Ratio Chart Width (inches)
#				4						Ratio Chart Height (inches)
#				1						Measurement Chart Width (inches)
sub parseparametertable
{
	my $fh = shift;
	my $fin = shift; # Get file name
	seek $fh, 0, 0;
	my @linearr;
	my $col;
	my $linenum = -1; # track line number
	my %paramhash; # conversion hash of grams and inches
	my $paramobj; # conversion object

	# read lines from parameter table
    while ( <$fh> )
	{
		chomp;
		$linenum++; # increment line number
		next if /^#/; # skip lines beginning with # comment
		@linearr = split "\t"; # split line on whitespace
		
#		next if @linearr == 0; # discard lines with no information
        # Sometimes I've noticed a first line with only a "." 
        # lines with 0, 1, or more than 2 items must be rejected
        next if @linearr != 2; # must have 2 items, a key and value
		# Make the first col the value and the second col the key
		$paramhash{ $linearr[ 1 ] } = $linearr[ 0 ];
		
	} # while ( <$fh> )
	
	$paramobj =
					new SOM::SOMtables( 'parametertable', $fin );	# add table name
	$paramobj->addparamhash( \%paramhash );
	
	# Dump hash
	$paramobj->paramtableprint( );

		# Check that all parameters are present in the
		# parameter table by checking against the 
		# %parameterlist hash.
	my $missingparam = 0;
	foreach ( sort keys %parameterlist )
	{
		 next if exists $paramhash{ $_ };
		 logprint "==>Missing parameter: $_\n";
		 $missingparam++;
	}
	
	if ( $missingparam )
	{
		die "Missing parameters must be added to the parameter file.\n";
	}
	
		# Check that all parameters have values
	my $missingparamval = 0;
	foreach ( sort keys %paramhash )
	{
		
		# next unless $paramhash{ $_ } eq '';
		next unless $paramhash{ $_ } eq '' || $paramhash{ $_ } =~ /^\s+/;
		logprint "==>Missing value for : $_\n";
		$missingparamval++;
	}
	
	if ( $missingparamval )
	{
		die "Missing values must be added to the parameter file.\n";
	}

	logprint "++Color and Font Check.\n";
	foreach ( sort keys %paramhash )
	{
		if ( /color/i )
		{
			logprint "-color param: $_ = ",$paramhash{ $_ };
			
			
			CASE:
			{
				exists $colors{ $paramhash{ $_ } } && do
					{
						logprint " --Exists in spot colors Hash.\n";
						last CASE;
					};
				exists $processcolors{ $paramhash{ $_ } } && do
					{
						logprint " --Exists in process colors hash.\n";
						last CASE;
					};
				# default - doesn't exist
				logprint "**WARNING** The color: ", $paramhash{ $_ }, " is not a process color",
							" or a known spot color. Please add it to the list of colors and try again.\n";
							
			} # End CASE
		} # if ( /color/i )
	} # foreach ( sort keys %paramhash )
	
	foreach ( sort keys %paramhash )
	{
		if ( /font$/i )
		{
			logprint "-font param: $_ = ",$paramhash{ $_ };
			if ( exists $fonts{ $paramhash{ $_ } } )
			{
				logprint "--Exists in fonts hash.\n";
			} else
			{
				logprint " **WARNING** The font: ", $paramhash{ $_ }, " is not in the font list. ",
							"Please add it to the list of fonts and try again.\n";
			}
		} # if ( /font$/i )
	} # foreach ( sort keys %paramhash )
#	foreach ( sort keys %fonts )
#	{
#		logprint "-Fonts: key: $_; val: ", $fonts{ $_ }, "\n";
#	} 	

	return $paramobj;
} # sub parseparametertable
#===========================================================#
# This is taken care of in the ratiotable procedure because
# most of the time the measurement tables are contained in the same
# file as the ratio tables.
sub parsemeasurementtables
{

} # sub parsemeasurementtables
#===========================================================#

# In a normal  file, the grams will increase, but the inches
# will decrease

#    T30208CP	# example of normal file					
#
#    Grams	Inches			Grams	Inches	
#    20	    2.6325			90	    1.6196	
#    22	    2.6021			92	    1.6001	
#    22.5	2.5945			96	    1.5612	
#    24	    2.5716			99	    1.5319	
#    25	    2.5564			100	    1.5222	

# In this case, the grams increase as usual, but the
# inches column will also increase

#    T30304LW	# example of inverted measurements		
#
#    Grams	    Inches from base			
#    14.8	    0.2498			
#    15	        0.2548			
#    17.5	    0.3172			
#    18	        0.3240			
#    18.8	    0.3348			
#    20	        0.3510			
#    21	        0.3639			
#    22.5	    0.3833			
#    25	        0.4177			

# Parse conversion table - see example above
sub parseconversiontable
{
	my $fh = shift;
	my $fin = shift; # Get file name
	seek $fh, 0, 0;
	my @linearr;
	my $col;
	my $linenum = -1; # track line number
	my %convhash; # conversion hash of grams and inches
	my $convobj; # conversion object

    # read lines from conversion table
	while ( <$fh> )
	{
		chomp;
		$linenum++; # increment line number
		@linearr = split "\t"; # split line on whitespace
		
		next if @linearr == 0; # discard lines with no information
		
		$col = 0; # start first column
		# if first char non-numeric line -> headers
		# within first few lines
		if ( $linearr[ 0 ] =~ /grams/i or @linearr == 1 and $linenum < 5 ) # if first char non-numeric line -> headers
		{
			next;
		}
		
		$col = 0;
		my @tmparr = @linearr;
		my $v; # value 
        # Go through the array columns
        # Build a hash table of all the data pairs across the columns
		while ( @tmparr )
		{
			$_ = shift @tmparr;
			unless ( $_ )
			{
				$col++; # skip to next col if nothing there
#				logprint " col $col |";
			} else
			{
                # If something in col, we have a key/value pair
                # We are on the key column
				logprint "k $_|";
                # Shift off the value in the next column
				$v = shift @tmparr;
				logprint "v $v|";
                # Add the key/value to the $convhash
				$convhash{ $_ } = $v;
			}
		} # while ( @tmparr )
		logprint "\n";
	} # while ( <$fh> ) # file reading loop
	
	$convobj =
					new SOM::SOMtables( 'conversiontable', $fin );	# add table name
	$convobj->addconvhash( \%convhash );
	
	# Dump hash
#	$convobj->conversiontableprint( );

	return $convobj;
} # sub parseconversiontable
#===========================================================#
sub buildeps
{
	my ( $tableobjects ) = @_;
	my %objects; # Hash for table objects and names
	my $fh; # file handle
	# Place all objects into hash with object name keys
	# logprint "**Name of all table objects:\n";
	foreach ( @$tableobjects )
	{
		# logprint $_->gettablename( ), ": ", $_->getfilename, "\n";
		$objects{ $_->gettablename( ) } = $_; # Make hash entry
	}
	
	# Check for the existance of hash entries for conversiontable
	# and parametertable. These two tables are required for making
	# the eps file from data in the ration and measurement table objects
	unless ( exists $objects{ 'conversiontable' } )
	{
		# logprint "Conversion table doesn't exist\n";
		die "Conversion table doesn't exist\n";
	}
	unless ( exists $objects{ 'parametertable' } )
	{
		# logprint "Parameter table doesn't exist\n";
		die "Parameter table doesn't exist\n";
	}
	
	# Get parameter and conversion hash information that
	# will be added to each of the objects
	my $convhash = $objects{ 'conversiontable' }->getconvhash( );
	my $paramhash = $objects{ 'parametertable' }->getparamhash( );
	
	# Use the file name of the tables file to create
	# a name for the eps file.
	# Change the .txt to .eps, or add .eps if no extention
	# Also, add the convhash and paramhash information to each
	# object. The table objects need this information in order to
	# build the embedded eps segments.
	my $fname; # path and file name of eps file
	my $epsstring; # String content of eps file
	my $epswidth;
	my $tmpstr;
	my $tmpwidth;
	my $epsheight;

	# logprint "Sorted names:\n";
	# Build ratio Tables
	foreach ( sort keys %objects )
	{
		# logprint "$_\n";
			# Add the paramhash info to each object
		$objects{ $_ }->addparamhash( $paramhash );
			# Add the conversion hash info to each object
		$objects{ $_ }->addconvhash( $convhash );
			# Add color hash info to each object
		$objects{ $_ }->addcolorhash( \%colors );
			# Add font hash info to each object
		$objects{ $_ }->addfonthash( \%fonts );
			# Add ratio compiler version info to each object
		$objects{ $_ }->addversion( $ratiocompilerver );
			# Get file name information in order to create 
			# eps destination file name
		if ( ( not $fname ) && /^table\d\d/ )
		{
			$fname = $objects{ $_ }->getfilename( );
			# logprint "object name: $_; File name: $fname\n";
			$fname .= '.eps' unless ( $fname =~ s/\.txt$/\.eps/ );
			# logprint "New file name: $fname\n";
		}
			# Build embedded eps for each table
		if ( /^table\d\d/ )
		{
			( $tmpstr, $tmpwidth, $epsheight ) = $objects{ $_ }->buildtableeps( 'ratio' );
			$epsstring .= $tmpstr;
			$epswidth += $tmpwidth;
			# logprint "--rwidth of this eps: $tmpwidth; total width: $epswidth\n";
		}
		
	} # foreach ( sort keys %objects )
	
	my $m_epsstring; # String content of eps file
	# Build measurement tables
	foreach ( sort keys %objects )
	{
		# logprint "$_\n";

			# Build embedded eps for each table
		if ( /^table\d\d/ )
		{
			# $m_epsstring .= $objects{ $_ }->buildtableeps( 'measurement' );
			( $tmpstr, $tmpwidth, $epsheight ) = $objects{ $_ }->buildtableeps( 'measurement' );
			$m_epsstring .= $tmpstr;
			$epswidth += $tmpwidth;
			# logprint "--mwidth of this eps: $tmpwidth; total width: $epswidth inches; ";
			# logprint $epswidth * 72, " points; Height: $epsheight points; ", $epsheight / 72, " inches \n";
		}

	} # foreach ( sort keys %objects )
	my $mcloc; # Measurement chart location - right or left
	$mcloc = $objects{ 'table00' }->getmeasurementchartlocation( );
		# measurement chart on right or left?
	# logprint "Measurement Chart Location: $mcloc\n"; 
	# Put together all of the tables, placing measurement tables either to the
	# right or left of the ratio tables
	$epsstring = $mcloc =~ /right/i?$epsstring.$m_epsstring:$m_epsstring.$epsstring;
	# Wrap the main eps header around the nested table eps file segments
	# We can use 'table00' epsheader function to generate the overall file header
	my $fileheader = 1; # This is not an embedded eps header or trailer
	$epsstring = $objects{ 'table00' }->epsheader( 0, 0, $epswidth * 72, $epsheight, $fileheader ) . 
								$epsstring . $objects{ 'table00' }->epstrailer( $fileheader );
	logprint "New file name: $fname\n";
	open $fh, ">$fname";
	print $fh $epsstring;
} # sub buildeps
#===========================================================#
1; # end of SOMcontrol module
