#!/usr/bin/perl

use strict;
use warnings;

my $usage = "Input in form $0 <vcf file><samtools idxstats>\n\n";

$ARGV[1] || die print $usage;

`cut -f 1 $ARGV[0] >> working1`;
`sort -u working1 |grep -v "#"  >> working2`;
`cut -f 1,2 $ARGV[1] >> working3`;

open(IN1, "working1");
my @SNPS = <IN1>;
chomp @SNPS;
open(IN2, "working2");
my @UNIQ = <IN2>;
chomp @UNIQ;
open(IN3, "working3");
my @LENGTH = <IN3>;
chomp @LENGTH;
#print @SNPS;
#print @UNIQ;
#print @LENGTH;

foreach my $line (@UNIQ){
	my $count = grep {/$line/} @SNPS;
	my ($contlen) =   grep {/$line/} @LENGTH;
	my $length = (split("\t", $contlen))[1];
	my $rate = sprintf("%.5f", $count/$length);
	print "$line\t$rate\n";
	}



`rm working*`;


exit;


