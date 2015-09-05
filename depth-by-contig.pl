#!/usr/bin/perl

use strict;
use warnings;

my $usage = "Use in form $0 <samtools depth output>\n\nFurther processing can be done using grep commands or through building other simple parsing scripts\n\n";

$ARGV[0] or die|| print $usage;

my $infile = shift @ARGV;
open (IN1, $infile);
my %contigs;
while (<IN1>){
	    chomp;
#places the values of a samtools depth output into keys (contig name) and assigns values for each locus.  
		    my($key, $value) = (((split "\t", $_))[0], (split ("\t", $_))[2]);
			    push @{$contigs{$key}} , $value ;
}
foreach my $key (keys %contigs){
	my $avg;
	my $sum;
#here the depth at every locus are summed together.
	$sum += $_ for @{$contigs{$key}};
#here they are avearaged over the total sum of loci.
	$avg = sprintf ("%.3f", $sum/($#{$contigs{$key}}+1));
	print $key . "\t" . $avg . "\n" ;
}

exit
