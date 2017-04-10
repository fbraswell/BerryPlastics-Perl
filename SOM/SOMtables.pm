package SOM::SOMtables;

# Copyright (c) 2007 Systems of Merritt, Inc.
# Written by Frank Braswell for Berry Plastics

# This package is responsible for building the PostScript EPS file.

# use strict;
use SOM::myutils;
use SOM::getopt;

print "load SOMtables.pm\n";
#===========================================================#
	# The following closures control access to 
	# important control variables.
{
	my $boxyval = 0; # Y value of possible Mexico code box - init to 0
	sub setboxyval { ( $boxyval ) = @_ }
	sub getboxyval { return $boxyval }
}
#===========================================================#
	# Global Variables
my $firstheader = 1; # True if first EPS header, false if embedded EPS headers
my $firsttrailer = 1; # True if first EPS trailer, false if embedded EPS trailers
my %static_parameters =
(
		# This is for numbers above the line (in points)
		# Characters are shifted up by positive numbers
		# Characters are shifted down by negative numbers
	'baseline offset' => 2,
		# This is for numbers below the line (in points)
		# Characters are shifted up by positive numbers
		# Characters are shifted down by negative numbers
	'negative baseline offset' => 0,
		# This raises the header up off the start line and table info line
		# in points
	'header offset' => 10,
);
my %processcolors = 
(
	'Cyan' => "1 0 0 0",
	'Magenta' => "0 1 0 0",
	'Yellow' => "0 0 1 0",
	'Black' => "0 0 0 1",
);
#===========================================================#
sub new
{
	my ( $pkg, $name, $fname ) = @_;
	# Place a leading 0 in front of table numbers less than 10
	# $name =~ s/table(\d)$/table0$1/;
	my %rpt =
	(	
		# Name of the table will have the form "table#"
		'tablename' => $name,
		# Name of file where table is found
		'filename' => $fname,
		# Beginning index of slice
		'beginind' => -1,
		# Ending index of slice
		'endind' => -1,
		# Length of slice
		'slicelen' => -1,
		# Number of rows
		'tablerows' => 0, # First row added below
		
		# The table array will contain the rows and columns of 
		# the ratio table information
		'tablearray' => [ ],
		
		# Hash for conversion table
		# 'convhash' => 'dummy',
		
		# Hash for control table
		# 'paramhash' => 'dummy',		
		
		# Hash for font table
		# 'fonthash' => 'dummy',
		
		# Hash for color table
		# 'colorhash' => 'dummy',	
		
		# PS code
		# 'pscode' => 'dummy',
		
		# Ratio Compiler Version
		# 'version' => 'dummy',
	);
	### DEBUG ### logprint "-->define table: $name<--\n";
	
#		logprint "=print process color hash\n";
#		foreach ( sort keys %processcolors )
#		{
#			logprint "color: $_; info: ", $processcolors{ $_ }, "\n";
#		}
#		logprint "=end color hash\n";	
	
	bless \%rpt, $pkg;
	return \%rpt;
} # end of sub new
#===========================================================#
# Return table name
sub gettablename
{
	my ( $pkg ) = @_;
	return $pkg->{ 'tablename' };
} # end gettablename
#===========================================================#
# Return file name
sub getfilename
{
	my ( $pkg ) = @_;
	return $pkg->{ 'filename' };
} # end getfilename
#===========================================================#
# Return table array
sub tablearray
{
	my ( $pkg ) = @_;
	return $pkg->{ 'tablearray' };
} # end tablearray
#===========================================================#
# print table
sub tableprint
{
	my ( $pkg ) = @_;
	logprint "Ratio table from: ", $pkg->{ 'tablename' }, "\n";
	for ( my $i = 0; $i < $pkg->{ 'tablerows' }; $i++ )
	{
		logprint "row $i: ";
		foreach ( @{ $pkg->{ 'tablearray' }[ $i ] } )
		{
			logprint "\t$_|";
		}
		logprint "\n";
	}
	logprint "End Ratio table from tableprint \n";
} # end tableprint
#===========================================================#
sub buildtableeps
{
	my ( $pkg, $tabletype ) = @_;
	my $epsstr; # String for building eps
	my $vlo_str; # vertical line outside proc
	my $vli_str; # vertical line inside proc
	my $sl_str; # start line proc
	my $col_str; # column line and text proc
	my $hlo_str; # horizontal line outside proc
	my $hdr_str; # header text and horizontal line
	my $makeratiotable = $tabletype =~ /ratio/i; # Type of table to produce
		# Get the smallest index from the conversion table
		# This will be used to determine the vertical size and
		# offset of the table
	my $smallind = ( sort { $a <=> $b } keys %{ $pkg->{ 'convhash' } } )[ 0 ];
		# Find the max length, which is determined from the smallind entry
	my $maxlen = $pkg->{ 'convhash' }->{ $smallind };
		# Round the length up the next integer
	my $maxlenint = int ( $maxlen + 1 );
	my $colname; # tmp variable for name
	my $colkey; # tmp variable for key to conversion hash
	my $coloffset; # tmp variable for offset
	my $ta = $pkg->{ 'tablearray' }; # Shorthand for ratio table
	my $ch = $pkg->{ 'convhash' }; # Shorthand for conversion hash
	my $ph = $pkg->{ 'paramhash' }; # Shorthand for parameter hash
	my $tn = $pkg->{ 'tablename' }; # Get table name
	my $ver = $pkg->{ 'version' }; # Get ratio compiler version
		# Ratio Column Width
#	my $rcw = .25; ####
		# Ratio Column Height
#	my $rch = $maxlenint; ######	
		# Get number of columns
	my $tablecols = $#{ $ta->[ 0 ] };
		# baseline offset (points) - lift chars up off ratio line
	# my $bo = 2;
	my $bo = $static_parameters{ 'baseline offset' };
		# negative baseline offset (points)
		# move chars down off ratio line
	my $nbo = $static_parameters{ 'negative baseline offset' };
		# offset for header line
	# my $ho = 15; 
	my $ho = $static_parameters{ 'header offset' };
	# Date and time information
	my ( $d, $t ) = timeofday_datetime( );
		# Parameter Table

#	Braswell					Operator Name
	my $on = ${ $ph }{ 'Operator Name' }; 
#	Paint Spot				Customer Name
	my $cn = ${ $ph }{ 'Customer Name' }; 
#	H486731_9108			Job Number
	my $jn = ${ $ph }{ 'Job Number' }; 
# T41032TP					Container Part Number	
	my $cpn = ${ $ph }{ 'Container Part Number' }; 			
#				5						Ratio Chart Width (inches)
	my $rcw = ${ $ph }{ 'Ratio Chart Width (inches)' }; 
#	$rcw = .25; ####
#				4						Ratio Chart Height (inches)
	my $rch = ${ $ph }{ 'Ratio Chart Height (inches)' }; 
#	$rch = $maxlenint; #############
#				1						Measurement Chart Width (inches)
		my $mcw = ${ $ph }{ 'Measurement Chart Width (inches)' };
#				4						Measurement Chart Height (inches)
		my $mch = ${ $ph }{ 'Measurement Chart Height (inches)' };
#				Right				Measurement Chart Location (on Right or on Left)
		my $mcl = ${ $ph }{ 'Measurement Chart Location (on Right or on Left)' };
#				0.1					Column Space (inches)
		my $cs = ${ $ph }{ 'Column Space (inches)' };
#				2						Vertical Line Weight Outside (points)
		my $vlwo = ${ $ph }{ 'Vertical Line Weight Outside (points)' };
#				1						Vertical Line Weight Inside (points)
		my $vlwi = ${ $ph }{ 'Vertical Line Weight Inside (points)' };
#				Blue				Vertical Line Color Outside
		my $vlco = ${ $ph }{ 'Vertical Line Color Outside' };
#				Black				Vertical Line Color Inside
		my $vlci = ${ $ph }{ 'Vertical Line Color Inside' };
#				0.25				Ratio Header Height
		my $rhh = ${ $ph }{ 'Ratio Header Height (inches)' };
#				Helvetica		Ratio Header Font
		my $rhf = ${ $ph }{ 'Ratio Header Font' };
#				Black				Ratio Header Font Color
		my $rhfc = ${ $ph }{ 'Ratio Header Font Color' };
#				8						Ratio Header Font Size (points)
		my $rhfs = ${ $ph }{ 'Ratio Header Font Size (points)' };
#				Helvetica		Ratio Column Font
		my $rcf = ${ $ph }{ 'Ratio Column Font' }; 
#				Black				Ratio Column Font Color
		my $rcfc = ${ $ph }{ 'Ratio Column Font Color' }; 
#				8						Ratio Column Font Size (points)
		my $rcfs = ${ $ph }{ 'Ratio Column Font Size (points)' }; 
#				1						Horizontal Line Weight (points)
		my $hlw = ${ $ph }{ 'Horizontal Line Weight (points)' };
#				Blue				Horizontal Line Color
		my $hlc = ${ $ph }{ 'Horizontal Line Color' };
#				Helvetica		Measurement Chart Font
		my $mcf = ${ $ph }{ 'Measurement Chart Font' };
#				Black				Measurement Chart Font Color
		my $mcfc = ${ $ph }{ 'Measurement Chart Font Color' };
#				8						Measurement Chart Font Size (points)
		my $mcfs = ${ $ph }{ 'Measurement Chart Font Size (points)' };
#		0.25						Ratio Chart Top Offset (inches)
		my $rcto = ${ $ph }{ 'Ratio Chart Top Offset (inches)' };
#		Above						Ratio Number Location (Above or Below)
		my $rnl = lc ${ $ph }{ 'Ratio Number Location (Above or Below)' };
#		1.5							Header Horizontal Line Weight (points)
		my $hhlw = lc ${ $ph }{ 'Header Horizontal Line Weight (points)' };
#		Magenta					Header Horizontal Line Color	
		my $hhlc = lc ${ $ph }{ 'Header Horizontal Line Color' };

		# Gather up the rest of the font and color parameters
		my ( $pscode ) = $pkg->getcolorcode( );
		
		# logprint "--pscode\n$pscode\n--colorDSCcode\n$colorDSCcode\n";
		#####
	my $mtlabel = ''; # measurement table label
	$_ = ${ $ta->[ 0 ] }[ 0 ];
	# Check for measurement table - it has info in row 0, col 0
	if ( $_ )
	{
		# Don't add this table with ratio tables
		# logprint "-Found measurement table: $tn - $_\n";
		# Return empty string if this call for measurement tables
		return "", 0, 0 if $makeratiotable;
	} else
	{
		# Don't add this table with measurement tables
		# logprint "-Found ratio table: $tn\n";
		# Return empty string if this call for ratio tables
		return "", 0, 0 unless $makeratiotable;
	} # if ( ${ $ta->[ 0 ] }[ 0 ] )
	
		# For a measurement table determine the label
		# that will follow the number
	MTLABEL:
	{
		/parts/i	&& do
					{
						$mtlabel = ' '; # no label
						last MTLABEL;
					};
		/ounces/i	&& do
					{
						$mtlabel = ' oz. ';
						last MTLABEL;
					};
		/ml/i	&& do
					{
						$mtlabel = ' ml ';
						last MTLABEL;
					};
	}
	
		# Set up header
	my $llx = 0;
	my $lly = 0;
		# width of ratio eps = num columns * col width + col spacing
		# width of measurement eps = measurement col widht + col spacing
		# convert to points with 72 pts/inch
	my $urx = $makeratiotable?( $tablecols * $rcw + $cs ) * 72:( $mcw + $cs ) * 72;
		# height of eps = chart height + 10pts for label at top
		# convert height to points with 72 pts/inch
	my $ury = $rch * 72 + 10;
	my $fileheader = 0; # This is an embedded header
	$epsstr .= epsheader( $pkg, $llx, $lly, $urx, $ury, $fileheader ); # Add header to string
	$epsstr .=
<<"EOS"
/bd { bind def } bind def
/ld { load def } bd
/ed { exch def } bd
/d /def ld
/m /moveto ld
/rm /rmoveto ld
/l /lineto ld
/rl /rlineto ld
/sh /show ld
/st /stroke ld
/gs /gsave ld
/gr /grestore ld
/inch { 72 mul } bd
/slw /setlinewidth ld

/rnlabove ($rnl) (above) eq d % Ratio number location (above or below)
% Center justify ratio numbers
% len is the width of the space the string must be centered in
/centershow % pass - str len aboveorbelow
{
	/above exch d
	2 copy pop exch % make extra copy of string
	2 div exch stringwidth pop 2 div sub % xoffset
	above % calculate the y offset
	{ % place number above
		bo % up by bo (baseline offset)
	}
	{ % place number below
		% bo rcfs add neg % move down by font size + baseline offset
		rcfs neg nbo add % move down by font size
	} ifelse
	rm % move into position
	sh % show char
} bd
% Center justify ratio header numbers
% This proc must center horizontally and vertically
% len is the width of the space the string must be centered in
/centershowhdr % pass - str len dummy
{
	pop % get rid of dummy boolean 
	2 copy pop exch % make extra copy of string
	2 div exch stringwidth pop 2 div sub % xoffset
	rhh inch yheight sub 2 div % calculate the y offset
	rm % move into position
	sh % show char
} bd
% Right justify from current point
/rightshow % pass str
{
	dup stringwidth pop % get width of str
	neg 0 rm % backup by stringwidth
	sh % show char
} bd
% ratio table variables
/bo $bo d % baseline offset
/nbo $nbo d % negative baseline offset
/ho $ho d % information header offset
/hfs 6 d % information header font
/hf_proc % information header font
{
	rcf findfont hfs scalefont setfont
} bind def

/ver $ver d % ratio comiler version
/on ($on) d % operator name
/cn ($cn) d % customer name
/jn ($jn) d % job number
/cpn ($cpn) d % container part number
/rcw $rcw d % width of col
/rch $rch d % height of col
/rcf /$rcf d % Ratio Column Font
/rcfc ($rcfc) d % ratio column font color
/rcfs $rcfs d % ratio column font size
/rcto $rcto d % Ratio Chart Top Offset (inches) 

/rcf_proc % Ratio Column Font
{
	rcf findfont rcfs scalefont setfont
} bind def

/cs $cs d % column spacing
/tablecols $tablecols d % number of ratio table cols
/vlwo $vlwo d % vertical line weight outside
/vlwi $vlwi d % vertical line weight inside
/vlco ($vlco) d % vertical line color outside
/vlci ($vlci) d % vertical line color inside
/rhh $rhh d % ratio header height
/rhf /$rhf d % ratio header font
/rhfc ($rhfc) d % ratio header font color
/rhfs $rhfs d % ratio header font size
/hhlw $hhlw d % header horizontal line weight under header text
/hhlc ($hhlc) d % header horizontal line color under header text

/rhf_proc % ratio header font
{
	rhf findfont rhfs scalefont setfont
} bind def

% Find the height of numbers for vertical centering
gs 
newpath 0 0 m rhf_proc
(1234567890) true charpath
flattenpath pathbbox
gr
	% calc yheight from ury - lly
exch pop exch sub /yheight ed % save yheight
pop % discard llx

/hlw $hlw d % horizontal line weight
/hlc ($hlc) d % horizontal line color
% /slo .125 d % offset from startline to top of ratio chart
/slo rcto d % offset from startline to top of ratio chart
/mcw $mcw d % width of measurement table
/mcf /$mcf d % measurement chart font
/mcfc ($mcfc) d % measurement chart font color
/mcfs $mcfs d % measurement chart font size

/mcf_proc % measurement chart font
{
	mcf findfont mcfs scalefont setfont
} bind def
%%%%%%%%%%%% color procs below
$pscode
%%%%%%%%%%%% color procs above
% Move origin to top - 
% all moves are negative from top
% 0 rch inch translate
0 rch inch slo add 15 add translate
% Put in header information only once
% if table00
($tn) (table00) eq
{
% rcf_proc % set rcf font
hf_proc % set information header font
0 0 0 1 setcmykcolor % black
% header information
% 0 ho rcto inch add m (Job Number: ) sh jn sh % job number
0 ho m 0 8 rm
(Job Number: ) sh jn sh % job number
( - Container Part Number: ) sh cpn sh % container part number
( - Customer Name: ) sh cn sh % customer name
0 ho m 
(Operator Name: ) sh on sh % operator name
( - Date and Time: $d $t) sh % show date and time
( - Ratio Compiler Version: ) sh ver 10 string cvs sh % ratio compiler version
} if
EOS
;

#				row 0: 	 |	10 |	1  |	5  |	# Headers
#				row 1: 	1|	60 |	66 |	96 |
#				row 2: 	2|	120|	132|	192|
#				row 3: 	3|	180|	198|	288|
#				row 4: 	4|	240|	264|	384|
#				row 5: 	5|	300|	330|	480|
#				row 6: 	6|	360|	396|	576|
#				row 7: 	7|	420|	462|	672|

	$sl_str .= 
<<"EOS"
% sl_str
% Move origin to top - 
% all moves are negative from top
% 0 rch inch translate
% Draw start line and label with table name
% rcf_proc % set rcf font
hf_proc % set information header font
0 0 0 1 setcmykcolor % black
% 0 bo rcto inch add m ($tn) sh % indicate start line
0 bo m ($tn) sh % indicate start line
.25 slw % very thin line
% 0 rcto inch m 
0 0 m  
EOS
;

	$sl_str .= $makeratiotable?
<<"EOS"
rcw $tablecols mul inch 0 rl st
EOS
:
<<"EOS"
mcw inch 0 rl st
EOS
;
	$vlo_str .= $makeratiotable?
<<"EOS"
% vlo_str
% Draw left hand line
vlwo slw % set outside linewidth
vlco % set vertical line color outside
0 slo neg inch m
% 0 rch neg inch l st
0 rch neg inch rl st
EOS
:'';	
	my $row0hdr; # Temp variable for header info
		# Traverse the ratio table by column (starting at row 1)
		# The first row (0) contains the header information
		# Go across each column starting at column 1
	for ( my $col = $tablecols == 0?0:1; $col <= $tablecols; $col++ )
	{
		
			# The column header (row 0) can be handled here
			#####
			$row0hdr = ${ $ta->[ 0 ] }[ $col ];
			# logprint "Row 0 header: $row0hdr\n"; 
			$hlo_str .= $makeratiotable?
<<"EOS"
% hlo_str
/x_val rcw $col 1 sub mul inch d
% Column Header
% gs
% Draw ratio chart horizontal line
hhlw slw % set line width
hhlc % set horizontal line color
x_val rhh slo add neg inch m 
rcw inch 0 rl st % draw line across
EOS
:'';

			$hdr_str .= $makeratiotable?
<<"EOS"
% hdr_str
/x_val rcw $col 1 sub mul inch d
% Draw header horizontal line
gs
vlwo slw % set line width
vlco % set horizontal line color
x_val slo neg inch m 
2 setlinecap
rcw inch 0 rl st % draw line across
gr
rhf_proc % set header font 
% rhf findfont rhfs scalefont setfont
rhfc % ratio header font color
% print header
x_val rhh slo add neg inch m 
($row0hdr) rcw inch true centershowhdr % true - place above line
$col 1 ne % skip if col 1?
{
% print colon
% rcw rhh slo add neg inch m 
x_val rhh slo add neg inch m
(:) 0 true centershowhdr % true - place above line
} if
% gr
EOS
:'';
		
			# Go down each row starting at row 1			
		for ( my $row = 1; $row < $pkg->{ 'tablerows' }; $row++ )
		{
			# The measuring label (number) is in column 0
			$colname = ${ $ta->[ $row ] }[ 0 ];
			$colkey = ${ $ta->[ $row ] }[ $col ];
				# DEBUG Might need to check to see if value exists
			$coloffset = $ch->{ $colkey + 0 };
			unless ( $coloffset )
			{
				logprint "--Warning - Value outside printable area!\n";
				logprint "---table name: $tn - row: $row; col: $col; name: $colname; Measurement Value: $colkey; offset: no value - skip to next value\n";
				next;
			}
			# logprint "-row: $row; col: $col; name: $colname; key: $colkey; offset: $coloffset; ";
			# logprint "table cols: $tablecols; table name: $tn\n";
			$col_str .= $makeratiotable?
<<"EOS"
% col_str - ratio
/x_val rcw $col 1 sub mul inch d
x_val $coloffset neg inch m 
rcf_proc % set ratio column font
rcfc % ratio column font color
($colname) rcw inch rnlabove centershow % rnlabove - ratio num above or below
hlw slw % set horizontal line width
hlc % horizontal line color
x_val $coloffset neg inch m  rcw inch 0 rl st
EOS
:
<<"EOS"
% col_str - measurement
/x_val 0 d
x_val $coloffset neg inch m 
mcw rcw sub inch 0 rm
mcf_proc % mcf measurement chart font & size
mcfc % measurement chart font color
($colname$mtlabel) rightshow
hlw slw % set horizontal line width
hlc % horizontal line color
rcw inch 0 rl st
EOS
;
			
		} # for ( my $row = 1; $i < $pkg->{ 'tablerows' }; $row++ )
		
		# Move over to the next column
			$vli_str .= $makeratiotable?
<<"EOS"
% vli_str
% Move over to next column
% rcw inch 0 translate
$col 1 ne % skip if col 1?
{
/x_val rcw $col 1 sub mul inch d
vlwi slw % set inside line width
vlci % set vertical line color inside
% draw vertical line on right side
x_val rhh slo add neg inch m 
% x_val rch neg inch l st
0 rch rhh sub neg inch rl st
} if
EOS
:'';		
	} # for ( my $col = 1; $col < $#{$pkg->{ 'tablearray' } }; $col++ )

# Draw line on right
	$vlo_str .= $makeratiotable?
<<"EOS"
% vlo_str
% Draw right hand line
/x_val rcw $tablecols mul inch d
vlwo slw % set outside linewidth
vlco % set vertical line color outside
x_val slo neg inch m
% x_val rch neg inch l st
0 rch neg inch rl st
EOS
:'';	

# Put together the sequencing from the above ps procs	
	$epsstr .=
<<"EOS"
% epsstr $sl_str $col_str $vli_str $hdr_str $hlo_str $vlo_str
EOS
;
	# $fileheader = 0 indicates this is not the file header - it is
	# an embedded eps
	$epsstr .= epstrailer( $pkg, $fileheader ); # Add trailer to string
		# Add PS code to translate over for the next table
		# translate by $tablecols * $rcw (table width) + $cs (col space)
	$epsstr .=
<<"EOS"
% epsstr
% Move over to next ratio table
/bd { bind def } bind def
/ld { load def } bd
/d /def ld
/m /moveto ld
/l /lineto ld
/rl /rlineto ld
/sh /show ld
/st /stroke ld
/gs /gsave ld
/gr /grestore ld
/inch { 72 mul } bd
% ratio table variables
/rcw $rcw d % width of ratio table col
/mcw $mcw d % width of measurement table
/cs $cs d % column spacing
/tablecols $tablecols d % number of ratio table cols
EOS
;

	$epsstr .= $makeratiotable?
<<"EOS"
% epsstr
tablecols rcw mul cs add inch 0 translate
EOS
:
<<"EOS"
% epsstr
mcw cs add inch 0 translate
EOS
;
	# Calculate the width of the table and pass it back
	my $xlatelen = $makeratiotable?$tablecols * $rcw + $cs: $mcw + $cs; 
	return $epsstr, $xlatelen, $ury; # Send back the eps string, width, height
} # sub buildtableeps
#===========================================================#
# add row to table
sub addtablerow
{
	my ( $pkg, $name, $beginind, $endind, @linearr ) = @_;
	### DEBUG ### logprint "++>table: $name; beginind: $beginind; endind: $endind; row: ",
	### DEBUG ### 			$pkg->{ 'tablerows' }, "<++\n";
	$pkg->{ 'beginind' } = $beginind;
	$pkg->{ 'endind' } = $endind;
	$pkg->{ 'slicelen' } = $endind - $beginind + 1;
	
	# Add the elements of the @linearr to the next row of tablearray
	push @{ $pkg->{ 'tablearray' }[ $pkg->{ 'tablerows' } ]}, 
																		splice @linearr, 
																		$pkg->{ 'beginind' },
																		$pkg->{ 'slicelen' };
	$pkg->{ 'tablerows' }++; # increment to next table row
	# push $pkg{ 'tablearray' }, $row;
} # end addtablerow
#===========================================================#
# add conversion hash
sub addconvhash
{
	my ( $pkg, $hashptr ) = @_;
	# Add it only if it doesn't already exist
	$pkg->{ 'convhash' } = $hashptr unless exists $pkg->{ 'convhash' };
	
} # end addconvhash
#===========================================================#
# Return conversion hash
sub getconvhash
{
	my $pkg = shift;
	return $pkg->{ 'convhash' };
} # sub getconvhash
#===========================================================#
# conversion table print
sub conversiontableprint
{
	my ( $pkg ) = @_;
	logprint "Conversion table from: ", $pkg->{ 'tablename' }, "\n";
	foreach ( sort { $a <=> $b } keys %{ $pkg->{ 'convhash' } } )
	{
		logprint "| key: $_, val: ", $pkg->{ 'convhash' }->{ $_ };
		logprint "\n";
	}
	logprint "End Conversion table from conversiontableprint\n";
} # end conversiontableprint
#===========================================================#
# Add color information
sub addcolorhash
{
	my ( $pkg, $hashptr ) = @_;
	# Add it only if it doesn't already exist
	$pkg->{ 'colorhash' } = $hashptr unless exists $pkg->{ 'colorhash' };
	
#		logprint "=print color hash\n";
#		foreach ( sort keys %{ $pkg->{ 'colorhash' } } )
#		{
#			logprint "color: $_; info: ", $pkg->{ 'colorhash' }->{ $_ }, "\n";
#		}
#		logprint "=end color hash\n";
		
} # end addcolorhash
#===========================================================#
# Get color information
sub getcolorhash
{
	my $pkg = shift;
	return $pkg->{ 'colorhash' };
} # sub getcolorhash
#===========================================================#
# Add font information
sub addfonthash
{
	my ( $pkg, $hashptr ) = @_;
	# Add it only if it doesn't already exist
	$pkg->{ 'fonthash' } = $hashptr unless exists $pkg->{ 'fonthash' };	
} # end addfonthash
#===========================================================#
# Get font information
sub getfonthash
{
	my $pkg = shift;
	return $pkg->{ 'fonthash' };
} # sub getfonthash
#===========================================================#
# get color eps code
sub getcolorcode
{
	my $pkg = shift;
	my $hdrcode; # EPS header comments
	my $hdrdcccode = '';
	my $hdrccccode = '';
	my $hdrdpccode = '';
	my $pscode = ''; # ps code string
		my $ph = $pkg->{ 'paramhash' }; # Shorthand for parameter hash
		# Parameter Table
#				Blue				Vertical Line Color Outside
		my $vlco = ${ $ph }{ 'Vertical Line Color Outside' };
		$pkg->getcolorps( 'vlco', $vlco, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#				Black				Vertical Line Color Inside
		my $vlci = ${ $ph }{ 'Vertical Line Color Inside' };
		$pkg->getcolorps( 'vlci', $vlci, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#				Black				Ratio Header Font Color
		my $rhfc = ${ $ph }{ 'Ratio Header Font Color' };
		$pkg->getcolorps( 'rhfc', $rhfc, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#				Black				Ratio Column Font Color
		my $rcfc = ${ $ph }{ 'Ratio Column Font Color' };
		$pkg->getcolorps( 'rcfc', $rcfc, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#				Blue				Horizontal Line Color
		my $hlc = ${ $ph }{ 'Horizontal Line Color' };
		$pkg->getcolorps( 'hlc', $hlc, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#				Black				Measurement Chart Font Color
		my $mcfc = ${ $ph }{ 'Measurement Chart Font Color' };
		$pkg->getcolorps( 'mcfc', $mcfc, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
#		Magenta					Header Horizontal Line Color
		## Debug 10-10-07 # my $hhlc = lc ${ $ph }{ 'Header Horizontal Line Color' }; # remove lc
		my $hhlc = ${ $ph }{ 'Header Horizontal Line Color' };
		$pkg->getcolorps( 'hhlc', $hhlc, \$hdrdcccode,	\$hdrccccode, \$hdrdpccode, \$pscode );
		
#		logprint "hdrdcccode: Document Custom Color Comments\n$hdrdcccode\n";
#		logprint "hdrccccode: CMYK Custom Color Comments \n$hdrccccode\n";
#		logprint "hdrdpccode: Document Process Color Comment\n$hdrdpccode\n";
#		logprint "pscode: PostScript code\n$pscode\n";
	$pkg->{ 'pscode' } = $hdrdpccode.$hdrdcccode.$hdrccccode;
	return ( $pscode );
} # getcolorcode
#===========================================================#
# Take a color name and build the EPS header and ps code procs
# The color will be either a process color or spot color

#		%%DocumentProcessColors:  Black
#		%%DocumentCustomColors: (PANTONE Cool Gray 4 C)
#		%%+ (PANTONE 186 C)
#		%%+ (Berry Blue)
#		%%+ (substrate)

#		%%CMYKCustomColor: 0 0 0 0.2400 (PANTONE Cool Gray 4 C)
#		%%+ 0 1 0.8100 0.0400 (PANTONE 186 C)
#		%%+ 1 0.5700 0 0.0200 (Berry Blue)
#		%%+ 0 0 0.5300 0 (substrate)

# spot color proc
#		/vlco
#		{
#			[
#				/separation
#				(colorname)
#				/DeviceCMYK
#				{	% proc to convert tint to cmyk
#					/FMB_tmp exch store % receive tint value
#					[ c m y k ] aload pop
#					4 { FMB_tmp mul 4 1 roll } repeat
#				}
#			] setcolorspace
#		} bind def

# process color proc
#		% (colorname)
#		 c m y k  setcmykcolor

sub getcolorps
{
	# pass variable name and color name, EPS header str, pscode str
	my ( $pkg, $varname, $colorname, $hdrdcccode, 
	$hdrccccode, $hdrdpccode, $pscode ) = @_;
	my $ctmp;
#		logprint "varname: $varname; colorname: $colorname\n";
#		logprint "=print color hash - in getcolorps\n";
#		foreach ( sort keys %{ $pkg->{ 'colorhash' } } )
#		{
#			logprint "color: $_; info: ", $pkg->{ 'colorhash' }->{ $_ }, "\n";
#		}
#		logprint "=end color hash\n";
	
	
	SWITCH:
	{
		# find the spot color
		defined $pkg->{ 'colorhash' }->{ $colorname } && do
			{
				$ctmp = $pkg->{ 'colorhash' }->{ $colorname };
				$$pscode .=
<<"EOS"
% spot color proc
/$varname
{
	[
		/Separation
		($colorname)
		/DeviceCMYK
		{	% proc to convert tint to cmyk
			/FMB_tmp exch store % receive tint value
			[ $ctmp ] aload pop
			4 { FMB_tmp mul 4 1 roll } repeat
		}
	] setcolorspace
} bind def
EOS
;
					# If $hdrdcccode is empty create the %%DocumentCustomColors: line
					# else create the %%+ line
					
					# Don't add if already in DSC comment	
				last SWITCH if $$hdrdcccode =~ /$colorname/;
				$$hdrdcccode .= 
$$hdrdcccode?
<<"EOS"
%%+ ($colorname)	
EOS
:
<<"EOS"
%%DocumentCustomColors: ($colorname)
EOS
;	
					# If $hdrccccode is empty create the %%CMYKCustomColor: line
					# else create the %%+ line
				$$hdrccccode .= 
$$hdrccccode?
<<"EOS"
%%+ $ctmp ($colorname)	
EOS
:
<<"EOS"
%%CMYKCustomColor: $ctmp ($colorname)
EOS
;			
				last SWITCH;
			};
		# find the process color
		defined $processcolors{ $colorname } && do
			{
				$ctmp = $processcolors{ $colorname };
				$$pscode .=
<<"EOS"
% process color proc
/$varname
{
% ($colorname)
 $ctmp  setcmykcolor
} bind def
EOS
;				
				# Don't add if already in DSC comment	
				last SWITCH if $$hdrdpccode =~ /$colorname/;
				$$hdrdpccode .=
$$hdrdpccode?
<<"EOS"
$colorname 
EOS
:
<<"EOS"
%%DocumentProcessColors: $colorname 
EOS
;
$$hdrdpccode =~ s/\n(.)/$1/; # get rid of cr in between words (not at eol)
				last SWITCH;
			};
		# set a default color if color not found as spot or process color above
		
				$$pscode .=
<<"EOS"
% spot color proc
/$varname
{
	[
		/Separation
		($colorname - Color not Found)
		/DeviceCMYK
		{	% proc to convert tint to cmyk
			/FMB_tmp exch store % receive tint value
			[ 0 1 1 0 ] aload pop
			4 { FMB_tmp mul 4 1 roll } repeat
		}
	] setcolorspace
} bind def
EOS
;
		
					# If $hdrdcccode is empty create the %%DocumentCustomColors: line
					# else create the %%+ line
					
					# Don't add if already in DSC comment	
				last SWITCH if $$hdrdcccode =~ /$colorname/; 
				$$hdrdcccode .= 
$$hdrdcccode?
<<"EOS"
%%+ ($colorname - Color not Found)	
EOS
:
<<"EOS"
%%DocumentCustomColors: ($colorname - Color not Found)
EOS
;	
					# If $hdrccccode is empty create the %%CMYKCustomColor: line
					# else create the %%+ line
				$$hdrccccode .= 
$$hdrccccode?
<<"EOS"
%%+ 0 1 1 0 ($colorname - Color not Found)	
EOS
:
<<"EOS"
%%CMYKCustomColor: 0 1 1 0 ($colorname - Color not Found)
EOS
;			
	
	}; # SWITCH
} # sub getcolorps
#===========================================================#
# add ratio compiler version
sub addversion
{
	my ( $pkg, $version ) = @_;
	# Add it only if it doesn't already exist
	$pkg->{ 'version' } = $version unless exists $pkg->{ 'version' };
	
} # end addparamhash
#===========================================================#
# add param hash
sub addparamhash
{
	my ( $pkg, $hashptr ) = @_;
	# Add it only if it doesn't already exist
	$pkg->{ 'paramhash' } = $hashptr unless exists $pkg->{ 'paramhash' };
	
} # end addparamhash
#===========================================================#
# Return param hash
sub getparamhash
{
	my $pkg = shift;
	return $pkg->{ 'paramhash' };
} # sub getparamhash
#===========================================================#
# Return param hash - Measurement Chart Location (on Right or on Left)
sub getmeasurementchartlocation
{
	my $pkg = shift;
	return $pkg->{ 'paramhash' }->{ 'Measurement Chart Location (on Right or on Left)' };
} # sub getmeasurementchartlocation
#===========================================================#
# param table print
sub paramtableprint
{
	my ( $pkg ) = @_;
	my $line;
	logprint "Parameter table from: ", $pkg->{ 'tablename' }, "\n";
	foreach ( sort keys %{ $pkg->{ 'paramhash' } } )
	{
		$line++;
		logprint "line: $line = val: ", $pkg->{ 'paramhash' }->{ $_ }, "\t\t\tkey: $_";
		logprint "\n";
	}
	logprint "End parameter table from paramtableprint\n";
} # end paramtableprint
#===========================================================#
# gettablePS
sub gettablePS
{
	my ( $pkg ) = @_;
	
} # end gettablePS
#===========================================================#
sub epsheader
{
	my ( $pkg, $llx, $lly, $urx, $ury, $fileheader ) = @_;
	my ( $d, $t ) = timeofday_datetime( );
	#### Add Font info!
	my $tmp = $pkg->{ 'pscode' };
	my $ver = $pkg->{ 'version' }; # Get ratio compiler version
	my $ph = $pkg->{ 'paramhash' }; # Shorthand for parameter hash
		#	Braswell					Operator Name
	my $on = ${ $ph }{ 'Operator Name' }; 
		#	Paint Spot				Customer Name
	my $cn = ${ $ph }{ 'Customer Name' }; 
		#	H486731_9108			Job Number
	my $jn = ${ $ph }{ 'Job Number' }; 
	$_ = "%%BeginDocument\n";
	# Do not add %%BeginDocument to the first
	# header
	if ( $fileheader )
	{
		$_ = ''; # Get rid of %%BeginDocument
	} 
	
	$_ .=
<<"EOS"
%!PS-Adobe-3.1 EPSF-3.0
%%Creator: Ratio Compiler $ver
%%--Creator: Adobe Illustrator(R) 12
%%--AI8_CreatorVersion: 12.0.1
%%For: ($on) (Berry Plastics)
%%Title: ($cn - $jn)
%%CreationDate: $d $t
%%BoundingBox: $llx $lly $urx $ury
%%HiResBoundingBox: $llx $lly $urx $ury
$tmp
%%EndComments 
%%BeginProlog
/u { } def
/U { } def
%%EndProlog
%%BeginSetup
%%EndSetup
%%BeginPageSetup
%%EndPageSetup
u
/SOMsv save def
EOS
	;
	return $_;
} # sub epsheader
#===========================================================#
sub epstrailer
{
	my ( $pkg, $fileheader ) = @_;

	$_ =
<<"EOS"
SOMsv restore
U
%%Trailer
%%EOF 
EOS
	;
	
	
	# Do not add %%EndDocument to the last trailer - only
	# add if an embedded eps
	unless ( $fileheader )
	{
		$_ .= "%%EndDocument\n";
	}
	
	return $_;
} # sub epstrailer
#===========================================================#
1; # end of package SOM::SOMtables;
