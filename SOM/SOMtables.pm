package SOM::SOMtables;

# Copyright (c) 2007 Systems of Merritt, Inc.
# Written by Frank Braswell for Berry Plastics

# This package is responsible for building the PostScript EPS file.

# use strict;
use SOM::myutils;
use SOM::getopt;

# print "load SOMtables.pm\n";
#===========================================================#
	# The following closures control access to 
	# important control variables.
{
	my  $boxyval = 0; # Y value of possible Mexico code box - init to 0
	sub setboxyval { ( $boxyval ) = @_ }
	sub getboxyval { return $boxyval }
}
#===========================================================#
	# Global Variables
my $firstheader = 1; # True if first EPS header, false if embedded EPS headers
my $firsttrailer = 1; # True if first EPS trailer, false if embedded EPS trailers
my $inchesdown = 1; # Default true, measure from bottom - false, measure from top
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
  logprint "\n";
  #	logprint "End Ratio table from tableprint \n";
} # end tableprint
#===========================================================#
sub buildtableeps
{
	my ( $pkg, $tabletype ) = @_;
  # $tabletype is either 'ratio' or 'measurement'
	my $epsstr; # String for building eps
	my $vlo_str; # vertical line outside proc
	my $vli_str; # vertical line inside proc
	my $sl_str; # start line proc
	my $col_str = ''; # column line and text proc
	my $hlo_str; # horizontal line outside proc
	my $hdr_str; # header text and horizontal line
      # $makeratiotalbe - ratio table (T) or measurement table (F)
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
  # Get all the parameter table variables
  # Create short variable names for each parameter

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
		# logprint "--pscode\n$pscode\n--colorDSCcode\n$colorDSCcode\n";  #####
  
  # Look at row 0, column 0 to determine if we have a
  # ratio table or measurement table.
  
  
  # Ratio table has nothing in row 0, col 0
  
  # Ratio Table has multiple columns
  #				row 0: 	 |	10 |	1  |	5  |	# Headers
  #				row 1: 	1|	60 |	66 |	96 |
  
  # Measurement table has 'ounces', 'parts' or 'ml' in row 0, col 0
  
  # Measurement Table only has one column
  #     row 0: 	Ounces  |     |
  #     row 1: 	0.5     |	14.8|

	my $mtlabel = ''; # measurement table label
	$_ = ${ $ta->[ 0 ] }[ 0 ];
	# Check for measurement table - it has info in row 0, col 0
	if ( $_ )
	{
		# Don't add this table with ratio tables
		# logprint "-Found measurement table: $tn - $_\n";
		# Return empty string if this call for measurement tables
      # $makeratiotalbe - ratio table (T) or measurement table (F)
		return "", 0, 0 if $makeratiotable;
	} else
	{
		# Don't add this table with measurement tables
		# logprint "-Found ratio table: $tn\n";
		# Return empty string if this call for ratio tables
      # $makeratiotalbe - ratio table (T) or measurement table (F)
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
#    /grams/i  && do
#          {
#            $mtlabel = ' grams ';
#            last MTLABEL;
#          };
		/ml/i	&& do
					{
						$mtlabel = ' ml ';
						last MTLABEL;
					};
    /cc/i  && do
          {
            $mtlabel = ' cc ';
            last MTLABEL;
          };
    # No matches
    logprint "#### WARNING #### Label '$_' doesn't match 'parts', 'ounces', 'ml' or 'cc'\n";
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
  logprint "#### Bounding Box: $llx, $lly, $urx, $ury\n";
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
  %%%%%% move the origin to the correct location %%%%%%
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

  # Ratio Table has multiple columns
#				row 0: 	 |	10 |	1  |	5  |	# Headers
#				row 1: 	1|	60 |	66 |	96 |
#				row 2: 	2|	120|	132|	192|
#				row 3: 	3|	180|	198|	288|
#				row 4: 	4|	240|	264|	384|
#				row 5: 	5|	300|	330|	480|
#				row 6: 	6|	360|	396|	576|
#				row 7: 	7|	420|	462|	672|

  # Measurement Table only has one column
  #     row 0: 	Ounces  |     |
  #     row 1: 	0.5     |	14.8|
  #     row 2: 	1       |	29.6|
  #     row 3: 	1.5     |	44.4|
  #     row 4: 	2       |	59.1|
  #     row 5: 	2.5     |	73.9|
  
  # The $makeratiotable variable decides whether a ratio
  # or measurement table is being built
  
	$sl_str .=  # start line proc
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

  # $makeratiotalbe - ratio table (T) or measurement table (F)
	$sl_str .= $makeratiotable?  # start line proc
<<"EOS"
rcw $tablecols mul inch 0 rl st
EOS
:
<<"EOS"
mcw inch 0 rl st
EOS
;
 
  # $makeratiotalbe - ratio table (T) or measurement table (F)
	$vlo_str .= $makeratiotable?  # vertical line outside proc
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
  
  # Outer loop
		# Go down each column starting at column 1
	for ( my $col = $tablecols == 0?0:1; $col <= $tablecols; $col++ )
	{
		
			# The column header (row 0) can be handled here
			#####
			$row0hdr = ${ $ta->[ 0 ] }[ $col ];
			# logprint "Row 0 header: $row0hdr\n";
    
  # $makeratiotalbe - ratio table (T) or measurement table (F)
  $hlo_str .= $makeratiotable?  # horizontal line outside proc
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

  # $makeratiotalbe - ratio table (T) or measurement table (F)
  $hdr_str .= $makeratiotable?  # header text and horizontal line
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
		
    # Inner loop
			# Go across each row starting at row 1
		for ( my $row = 1; $row < $pkg->{ 'tablerows' }; $row++ )
		{
			# The measuring label (number) is in column 0
			$colname = ${ $ta->[ $row ] }[ 0 ];
			$colkey = ${ $ta->[ $row ] }[ $col ];
				# DEBUG Might need to check to see if value exists
			$coloffset = $ch->{ $colkey + 0 };
			unless ( $coloffset )
			{
#				logprint "--Warning - Value outside printable area!\n";
				warn " Value outside printable area!\n";
				logprint "---table name: $tn - row: $row; col: $col; name: $colname; Measurement Value: $colkey; offset: no value - skip to next value\n";
        logprint "#### WARNING #### Can't print $tn - row: $row, col: $col\n";
				next;
			}
			# logprint "-row: $row; col: $col; name: $colname; key: $colkey; offset: $coloffset; ";
			# logprint "table cols: $tablecols; table name: $tn\n";
      
      # Adjust for measure from top - default is measure from bottom
      # Default true, measure from bottom - false, measure from top
      unless($inchesdown)
      {
        # adjust for measure from top
        $coloffset = $rch + $rcto + $rhh + (10 / 72) - $coloffset
      }
      #      logprint "????? inchesdown: $inchesdown; coloffset: $coloffset\n";
  # $makeratiotalbe - ratio table (T) or measurement table (F)
  $col_str .= $makeratiotable?  # column line and text proc
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
      
		# See if $col_str defined
        logprint "col_str not defined\n" unless defined $col_str;
        logprint "makeratiotable not defined\n" unless defined $makeratiotable;
        
		} # for ( my $row = 1; $i < $pkg->{ 'tablerows' }; $row++ )
		
		# Move over to the next column
  # $makeratiotalbe - ratio table (T) or measurement table (F)
  $vli_str .= $makeratiotable?  # vertical line inside proc
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
  # $makeratiotalbe - ratio table (T) or measurement table (F)
	$vlo_str .= $makeratiotable?  # vertical line outside proc
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
  # Report to log if PS code sections aren't defined
logprint "sl_str not defined for epsstr\n" unless defined $sl_str;  # start line proc
logprint "col_str not defined for epsstr\n" unless defined $col_str;  # column line and text proc
logprint "vli_str not defined for epsstr\n" unless defined $vli_str;  # vertical line inside proc
logprint "hdr_str not defined for epsstr\n" unless defined $hdr_str;  # header text and horizontal line
logprint "hlo_str not defined for epsstr\n" unless defined $hlo_str;  # horizontal line outside proc
logprint "vlo_str not defined for epsstr\n" unless defined $vlo_str;  # vertical line outside proc
  
  # Put everything together
	$epsstr .=
<<"EOS"
% epsstr $sl_str $col_str $vli_str $hdr_str $hlo_str $vlo_str
EOS
;
	# $fileheader = 0 indicates this is not the file header - it is
	# an embedded eps
	$epsstr .= epstrailer( $pkg, $fileheader ); # Add trailer to string  # String for building eps
		# Add PS code to translate over for the next table
		# translate by $tablecols * $rcw (table width) + $cs (col space)
	$epsstr .=  # String for building eps
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

  # $makeratiotalbe - ratio table (T) or measurement table (F)
	$epsstr .= $makeratiotable?  # String for building eps
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
# Determine direction of conversion table - up or down
#
# Key "up"/Value "down" is normal measure from bottom
# key is grams, value is in inches
# returns " - measurement: up - inches: down\n";
#    k 14.8|v 1.0766|
#    k 15|v 1.0716|
#    k 17.5|v 1.0092|
#    k 18|v 1.0024|
#    k 18.8|v 0.9916|
#    k 20|v 0.9754|

# Key "up"/Value "up" is rare, and represents measure from top
# Key is grams and value is inches
# returns " - measurement: up - inches: up\n";
#    k 14.8|v 0.2498|
#    k 15|v 0.2548|
#    k 17.5|v 0.3172|
#    k 18|v 0.3240|
#    k 18.8|v 0.3348|
#    k 20|v 0.3510|

sub dirconvhash
{
	my $pkg = shift;
    my $firstloop = 1;
    my $measurement = 'up';
    my $inches = 'up';
    my %chash = %{ $pkg->{ 'convhash' } }; # shorten reference
    my $prevkey = '';
    my $prevval = '';
    my $prevmeasurement = '';
    my $previnches = '';
    
    # the keys should always progress upward, the measurement values
    # the values can progress either way, the inches values
 #   logprint "Conversion table direction: ", $pkg->{ 'tablename' }, "\n";
	foreach ( sort { $a <=> $b } keys %chash )
	{
		# first loop doesn't check since no prev value
        if ($firstloop)
        { 
            # set to false and don't check directions
            $firstloop = 0;
        } else
        {
            # check directions second loop and beyond
            # check measurement info
            $measurement = $prevkey > $_? 'down':'up';
            # check inches info
            $inches = $prevval > $chash{ $_ }? 'down':'up';
        }
        
        # always save info for next loop
        $prevkey = $_;
        $prevval = $chash{ $_ };
	}
    $inchesdown = $inches eq 'down'; # true if down, false if up
  
  # Key "up"/Value "down" is normal measure from bottom
  # returns " - measurement: up - inches: down\n";
  
  # Key "up"/Value "up" is rare, and represents measure from top
  # returns " - measurement: up - inches: up\n";
  
  my $dir = $inches eq 'up'? "#### Direction: Measure from Top": "#### Direction: Measure from Bottom";
  
    return " - measurement: $measurement - inches: $inches\n$dir\n";
#	logprint "End Conversion table direction\n";
    
#	return $pkg->{ 'convhash' };
} # sub dirconvhash
#===========================================================#
# conversion table print
sub conversiontableprint
{
	my ( $pkg ) = @_;
	logprint "#### Conversion table Start from: ", $pkg->{ 'tablename' }, "\n";
  logprint "Grams\tInches\n\n";
	foreach ( sort { $a <=> $b } keys %{ $pkg->{ 'convhash' } } )
	{
    #		logprint "| key: $_, val: ", $pkg->{ 'convhash' }->{ $_ };
    logprint "$_\t\t", $pkg->{ 'convhash' }->{ $_ };
		logprint "\n";
	}
	logprint "#### Conversion table End from conversiontableprint\n";
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
  my $tempVal;
	logprint "#### Parameter table start from: ", $pkg->{ 'tablename' }, "\n";
	foreach ( sort keys %{ $pkg->{ 'paramhash' } } )
	{
		$line++;
    #		logprint "line: $line = val: ", $pkg->{ 'paramhash' }->{ $_ }, "\t\t\tkey: $_";
    #   my tempVal;
    $tempVal = $pkg->{ 'paramhash' }->{ $_ };
    logprint $tempVal;
    if (length $tempVal > 4)
    {
      logprint "\t\t---> $_";
    } else
    {
      logprint "\t\t\t---> $_";
    }
		logprint "\n";
	}
	logprint "#### Parameter table end from paramtableprint\n";
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
