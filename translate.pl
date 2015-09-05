#!/usr/bin/perl -w

#use in form translate.pl <assembly.fasta> <sequenceshit.aa.fasta> <blast.outfmt6.txt> <out-header>



use strict;

my $assembly = $ARGV[0];
my $reference = $ARGV[1];
my $blast_output = $ARGV[2];
my $org = $ARGV[3];

system "mkdir translated_seqs temp_files";

my %nucs = ();
&read_nucleotides($assembly);

my %prots = ();
&read_prots($reference);

my %blast = ();
open BL, "< $blast_output";
while (<BL>){
	chomp;
	my @a = split(/\t/,$_);
	my $query = $a[0];
	my $hit = $a[1];
	$blast{$query} = $hit;
}
close BL;

foreach my $transcript_id (keys %nucs){
	my $dna = $nucs{$transcript_id};
	open TO, "> $transcript_id.DNA";
	print TO ">$transcript_id\n$dna\n";
	close TO;
	open REF, "> $transcript_id.REF.FAA";
	my $ref_id = $blast{$transcript_id};
	my $ref_seq = $prots{$ref_id};
	print REF ">$ref_id\n$ref_seq\n";
	close REF;
	system "genewise $transcript_id.REF.FAA $transcript_id.DNA -pep -kbyte 40000000 -cdna -trans -both -sum > $transcript_id.OUT";
	if (-z "$transcript_id.OUT"){
		system "mv $transcript_id.* temp_files/";
	}
	else {
		system "parse_genewise.pl $transcript_id.OUT";
	}
}

system "cat translated_seqs/*.FNA > $org.TRANS.FNA";
system "cat translated_seqs/*.FAA > $org.TRANS.FAA";

sub read_nucleotides {
	my $file = $_[0];

	my $seq;
	my $header;

	open IN, "< $file";
	while (<IN>){
		chomp;
		if (/^>(\S+)/){
			if (defined($seq)) {
				$nucs{$header} = $seq;
			}
			$header = $1;
			$seq = "";
		}
		else {
			$seq .= $_;
		}
	}
	close IN;

	if (defined($seq)) {
		$nucs{$header} = $seq;
	}
}

sub read_prots {
	my $file = $_[0];

	my $seq;
	my $header;

	open IN, "< $file";
	while (<IN>){
		chomp;
		if (/^>(\S+)/){
			if (defined($seq)) {
				$prots{$header} = $seq;
			}
			$header = $1;
			$seq = "";
		}
		else {
			$seq .= $_;
		}
	}
	close IN;

	if (defined($seq)) {
		$prots{$header} = $seq;
	}
}

exit;
