#!/usr/bin/perl -w

# This program is launched from the BerryPlastics.app
# It initiates the procedures from the SOMcontrol package.

use strict;
use FileHandle;
use Cwd;
# use SOM::SOMcontrol( 'initstuff', 'processjob' );
# Copyright (c) 2007 Systems of Merritt, Inc.
# Written by Frank Braswell
# Flush data immediately to stdout.
# autoflush STDOUT 1;
	# Look in the current folder first for included modules

# use lib "/Users/frankbraswell/Business\ Folders/Berry\ Plastics/test/";

# Hard coded path
# use lib "/Users/frankbraswell/Library/Developer/Xcode/DerivedData/BerryPlastics-aupxqpnqgjeglqgpzflvqhogeops/Build/Products/Release/";
my $ppath;
BEGIN
{
    # Grab the program path from $0
    # $0 is the name of the program containing this script, 
    # including the path
        ($ppath) = $0 =~ /(.+\/)/;
}
# print STDOUT "prog path: $ppath\n";

use lib $ppath;

# print STDOUT "getcwd: ", getcwd(), "\n";

use lib ".";
# print STDOUT "-----Start Berry Plastics Program -----\n";
print "-----Start Berry Plastics Program -----\n";
autoflush STDOUT 1;
# Pass in external procedures from SOMcontrol, used below
use SOM::SOMcontrol( 'initstuff', 'processjob' );

# print "-----Start Program -----\n";

	# Flush data immediately to stdout.
# autoflush STDOUT 1;

# Do any initial stuff before launching the main 
# part of the program
initstuff();

# Do the heavy lifting with processjob.
my $status = processjob();

# Print the final status - done in processjob
# print "++processjob status: $status\n";

print "-----End Program -----\n";

exit;
