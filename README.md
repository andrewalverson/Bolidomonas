#Kessenich et al. 2014. J Phycol. 50(6): 977–983
[TOC]

# Identification of allelic variation

## Assembly and Annotation #

Trim reads with _SeqTK_:
```
#!Bash
seqtk trimfq -b 12 -e 6
```

Assemble trimmed reads with _Trinity_:
```
#!Bash
Trinity.pl --seqType fq --left <Trimmed_R1.fq> --right <Trimmed_R2.fq> --CPU <n-procs> --JM 768G > trinity.log
```

BLASTX assembled reads for translation and annotation:
```
#!Bash
blastx -query <trinity.fasta> -db <path-to-db/db> -outfmt 6 -num_threads <n-procs> -max_target_seqs 1 >> **species_hits.blastx**
```

Use accession numbers or GI's from **species_hits.blastx** to retrieve fasta files (**species_hits.fasta**) of the top hits.

Ensure _Genewise_ is installed  and **parse_genewise.pl** is in your $PATH. Run ```translate.pl``` to translate contigs assembled by Trinity (**trinity.fasta**):
```
#!Perl
./translate.pl <trinity.fasta> <species_hits.fasta> <species_hits.blastx>  <output_name>
```
Output: **output_name.TRANS.FNA** and **output_name.TRANS.FAA**

It is important to remove redundant sequences before proceeding. The following scripts remove redundant sequences and identify sequences with spurious non-ATGCN characters that are sometimes accidentally introduced by ```translate.pl```

Note: 'NR' added to output_name to indicate that the ouput contains non-redundant sequences.
```
#!Python
./removenonATGC.py <output_name.TRANS.FNA> | ./fastadupedump.py /dev/stdin > temp; mv temp NR_output_name.TRANS.FNA
```

## Read Mapping and SNP calling
Reads can be mapped to the assembly using either _bowtie_ directly or by running _bowtie_ through the _Trinity_ package.
```
#!Perl
path-to-trinity-package/alignReads.pl --left <Trimmed_R1.fq> --right <Trimmed_R2.fq> --seqType fq --target <NR_output_name.TRANS.FNA> --aligner bowtie --p <n-procs>
```

Make sure SAMtools is installed.

Run the following command on **bowtie_out.coordSorted.bam**, which is located in the **bowtie_out** folder:
```
samtools mpileup -uf <NR_output_name.TRANS.FNA>  <bowtie_out.coordSorted.bam> | bcftools view -vcg > out_name.vcf
```

**out_name.vcf** contains every variant site, including the depth at that locus. The following command will scan the VCF file for loci with >= 20 depth and Phred >= 20:
```
#!Perl
vcfutils.pl varFilter -d 20 <out_name.vcf> | awk '$6>=20' > 20.20.out_name.vcf
```

The following command returns the number of contigs >= 1 variant site:
```
#!Bash
cut -f 1 <20.20.out_name.vcf> | sort -u | wc -l
```

THE following command returns the total number of variant sites called at that depth/Phred cutoff:
```
#!Bash
cut -f 1 <20.20.out_name.vcf> | wc -l
```

Run the following commands to get the number of mistmatches per contig. These values can then be summed and averaged to get global mismatch densities:
```
samtools idxstats <bowtie_out.coordSorted.bam> >> idxstats.out
./mismatch-by-contig.pl <20.20.vcf> <idxstats.out> 
```
>NOTE:  if you want depth/Phred values that are not 20/20 then your naming scheme should reflect that

##MCL ortholog clustering #
The following scripts require unique FASTA headers. Currently headers read ">compXXXXX_cX_seqX"
Run the following to assign unique FASTA headers for each species, where NEWNAME is a unique species identifier:
```
sed -i 's/comp/NEWNAME_/g' NR_out_name.FNA
```

Now all "compXXXX_cX_seqX" have become "NEWNAME_XXXX_cX_seqX".

Concatenate all individual **amino acid** sequence files into a single file:
```
cat *NR_*.AA  > all_AA.faa
```

Make a BLASTP database:
```
makeblastdb -in all_AA.faa -dbtype prot
```

Run all-versus-all BLASTP with tabular output:
```
blastp -query <all_AA.faa> -db <all_AA.faa> -outfmt 6 -num_threads <n-procs> -out all_AA.tab
```

Perform MCL custering
```
./mcl_run.sh all_AA.tab 2.3
```

Gene families are ouput into out.seq.mci.I##.