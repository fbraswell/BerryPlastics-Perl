#!/usr/bin/perl -w
use strict;
use FileHandle;
use Cwd;
# Copyright (c) 2007 Systems of Merritt, Inc.
# Written by Frank Braswell
# Flush data immediately to stdout.
autoflush STDOUT 1;
	# Look in the current folder first for included modules

# use lib "/Users/frankbraswell/Business\ Folders/Berry\ Plastics/test/";

# Hard coded path
# use lib "/Users/frankbraswell/Library/Developer/Xcode/DerivedData/BerryPlastics-aupxqpnqgjeglqgpzflvqhogeops/Build/Products/Release/";
my $ppath;
BEGIN
{
        ($ppath) = $0 =~ /(.+\/)/;
}
# print STDOUT "prog path: $ppath\n";

use lib $ppath;

# print STDOUT "getcwd: ", getcwd(), "\n";

use lib ".";
print STDOUT "-----Start Berry Plastics Program -----\n";
# Pass in external procedures.
use SOM::SOMcontrol( 'initstuff', 'processjob' );

# print "-----Start Program -----\n";

	# Flush data immediately to stdout.
# autoflush STDOUT 1;

initstuff();

my $status = processjob();
print "processjob status: $status\n";

print "-----End Program -----\n";

exit;
