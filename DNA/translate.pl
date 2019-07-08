#!/usr/bin/perl -w
#luhuifang
#2015/8/6
#trans CDS to amino acid

use strict;
use Getopt::Long;

my($file,$out);
GetOptions(
	"help|?"=>\&USAGE,
	"file:s"=>\$file,
	"out:s"=>\$out,
);
&USAGE unless ($file && $out);

my %CODE = (
			'GCA' => 'A', 'GCC' => 'A', 'GCG' => 'A', 'GCT' => 'A',                               # Alanine
			'TGC' => 'C', 'TGT' => 'C',                                                           # Cysteine
			'GAC' => 'D', 'GAT' => 'D',                                                           # Aspartic Acid
			'GAA' => 'E', 'GAG' => 'E',                                                           # Glutamic Acid
			'TTC' => 'F', 'TTT' => 'F',                                                           # Phenylalanine
			'GGA' => 'G', 'GGC' => 'G', 'GGG' => 'G', 'GGT' => 'G',                               # Glycine
			'CAC' => 'H', 'CAT' => 'H',                                                           # Histidine
			'ATA' => 'I', 'ATC' => 'I', 'ATT' => 'I',                                             # Isoleucine
			'AAA' => 'K', 'AAG' => 'K',                                                           # Lysine
			'CTA' => 'L', 'CTC' => 'L', 'CTG' => 'L', 'CTT' => 'L', 'TTA' => 'L', 'TTG' => 'L',   # Leucine
			'ATG' => 'M',                                                                         # Methionine
			'AAC' => 'N', 'AAT' => 'N',                                                           # Asparagine
			'CCA' => 'P', 'CCC' => 'P', 'CCG' => 'P', 'CCT' => 'P',                               # Proline
			'CAA' => 'Q', 'CAG' => 'Q',                                                           # Glutamine
			'CGA' => 'R', 'CGC' => 'R', 'CGG' => 'R', 'CGT' => 'R', 'AGA' => 'R', 'AGG' => 'R',   # Arginine
			'TCA' => 'S', 'TCC' => 'S', 'TCG' => 'S', 'TCT' => 'S', 'AGC' => 'S', 'AGT' => 'S',   # Serine
			'ACA' => 'T', 'ACC' => 'T', 'ACG' => 'T', 'ACT' => 'T',                               # Threonine
			'GTA' => 'V', 'GTC' => 'V', 'GTG' => 'V', 'GTT' => 'V',                               # Valine
			'TGG' => 'W',                                                                         # Tryptophan
			'TAC' => 'Y', 'TAT' => 'Y',                                                           # Tyrosine
			'TAA' => 'U', 'TAG' => 'U', 'TGA' => 'U'                                              # Stop
);

open IN,"< $file" or die "$!";
open OUT,"> $out" or die "$!";

my $prot;
my %prot=();
$/=">";<IN>;$/="\n";
while(<IN>){
	my $head=$_;
        my $key=$1 if ($head=~/^(\S+)\s+/);
#	print OUT ">$key\n";
        $/=">";
        my $seq=<IN>;
        $seq=~s/\s+//g;
        $/="\n";
	
	for(my $i=0;$i<=length($seq);$i+=3){
		my $code=substr($seq,$i,3);
		last if (length($code) < 3);
		$prot.=(exists $CODE{$code})? $CODE{$code}:"X";
	}
	$prot{$key}=$prot;
	$prot=undef;
}
foreach my $base(keys %prot){
	my $protein=&line($prot{$base},60);
	print OUT ">$base\n$protein";
}

close IN;
close OUT;


sub line{
	my $dis;
	my ($seq,$width)=@_;
	for(my $i=0; $i<=length($seq); $i+=$width){
		$dis.=substr($seq,$i,$width)."\n";
	}
	return $dis;
}


sub USAGE{
  my $usage=<<"USAGE";
Name:
$0 --Translate your CDS to amino acid

Description:
You can use it to translate your CDS file to amino acid, your infile should be *.fasta, and the sequences should be mRNA.

Usage:
  options:
  -file <must|file>	infile(*.fasta)
  -out	<must|file>	outfile(*.fasta)
  -h    Help

Example:
perl $0 -file cds.fasta -out portein.fasta

USAGE
  print $usage;
  exit;
 }
