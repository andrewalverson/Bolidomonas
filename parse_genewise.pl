#!/usr/bin/perl -w

use strict;

# ===============================================================================
# The input for this script is the output of genewise, where a reference protein
# is defined, and the query DNA sequence is a single unigene.
#
# For genewise, use:
#
# genewise REFERENCE QUERY -pep -cdna -trans -both -sum > QUERY.OUT
#
# This was part of a larger pipeline, but probably makes more sense to look at it
# as a single component. Let me know if you have questions or problems.
#
# ===============================================================================

my $file = $ARGV[0];

# This was part of a larger pipeline that defined the orthogroup and taxon, but to run this alone, define these:

my @order = ();
my $output_check = 0;

my %lines = ();
my %trans = ();
my $line;
my $score = "";
open IN, "< $file";
my $gene_id = "";
if ($file =~ /^(\S+)\.OUT/){
	$gene_id = $1;
}

# Get all sequences and their associated bitscores

while (<IN>){ 
	next if /^Bits/;
	next if /\/\//;
	next if /^Making/;
	if (/^(\d+)/){
		if (defined($line)){
			$lines{$score} = $line;
		}       
		$score = $1;
		$line = "";
	}       
	else {  
		$line .= $_;
	}       
}       
close IN;

if (defined($line)) {
	$lines{$score} = $line;
}

# DEBUG #

foreach my $bit (keys %lines){
	print "$bit\n";
}

# Because we look at the translations in both directions, the translation in the correct orientation will have a much higher bitscore
# So we take the translation with the highest bitscore

open BEST, "> $gene_id.BEST";
foreach my $bitscore (sort {$b <=> $a} keys %lines){
	my $data = $lines{$bitscore};
	print BEST "$bitscore\n$data\n";
	last;   
}       
close BEST;

# "Bad" translations will be annotated as either containing an intron, or stop codons - account for these here
# ***** Can these be accounted for using a gff? If we detect an intron flag, then we could run a subrouting using the gff?

my $best_out = "$gene_id.BEST";
&read_trans ($best_out);
my $intron_check = "";
my $stop_check = "";
foreach my $trans_id (@order){
	my $trans_check = $trans{$trans_id};
	if ($trans_check =~ /intron/){
		$intron_check = "INTRON";
	}
	elsif ($trans_check =~ /(\w+)\*(\w+)/){
		$stop_check = "STOP";
	}
}
if ($intron_check =~ /INTRON/){
	next;
	# *** Create subroutine to account for possible introns ***
}
elsif ($stop_check =~ /STOP/){
	next;
	# *** Create subroutine to account for possible stop codons ***
}
else {
	# Genewise will break sequences at frameshifts. Here, we can splice these together, using an X in the 
	# amino acid sequence, and NNN in the nucleotide sequence. This will preserve frame for forcing the DNA
	# alignment to the AA alignment.
	
	open FAA, "> $gene_id.TRANS.FAA";
	open FNA, "> $gene_id.TRANS.FNA";
	my $fragment_count = 0;
	my $fna_count = 0;
	print FAA ">$gene_id\n";
	print FNA ">$gene_id\n";
	foreach my $id (@order){
		if ($id =~ /^(\S+)\.sp\.tr/){
			my $translation = $trans{$id};
			if ($fragment_count > 0){
				print FAA "X";
			}
			$fragment_count++;
			print FAA "$translation";
		}
		elsif ($id =~ /^(\S+)\.sp$/){
			if ($fna_count > 0){
				print FNA "NNN";
			}
			$fna_count++;
			my $fna = $trans{$id};
			print FNA "$fna";
		}
	}
	print FAA "\n";
	print FNA "\n";
	close FAA;
	close FNA;
	$output_check++;
}
if ($output_check > 0){
	#system "cat *.$ortho.FAA > $org.$ortho.FAA";
	#system "cat *.$ortho.FNA > $org.$ortho.FNA";
	system "mv $gene_id.TRANS.* translated_seqs/";
	system "mv $gene_id.* temp_files/";
}
else {
	system "mv $gene_id.* temp_files/";
}

sub read_trans {
	my $infile = $_[0];

	my $seq = "";
	my $header = "";

	open IN, "< $infile";
	while (<IN>){
		chomp;
		if (/^>(\S+)/){
			if (defined($seq)) {
				$trans{$header} = $seq;
			}
			$header = $1;
			$seq = "";
			push (@order,$header);
		}
		else {
			$seq .= $_;
		}
	}
	close IN;

	if (defined($seq)) {
		$trans{$header} = $seq;
	}
}

exit;
