#!/usr/bin/perl -w
#luhuifang
#2015/8/11

use strict;
use Getopt::Long;

my ($file,$out);
GetOptions(
	"help|?"=>\&USAGE,
	"file:s"=>\$file,
	"out:s"=>\$out,
);
&USAGE unless($file && $out);

open IN, "< $file" or die "$!";
open OUT, "> $out" or die "$!";

my ($total_len,$eff_len,$N_len,$G_len,$C_len,$GC_len,$GC_rate)=(0,0,0,0,0,0,0);
while(<IN>){
	my $seq=<IN>;
	chomp($seq);
	$G_len += ($seq=~s/G/G/g);
	$C_len += ($seq=~s/C/C/g);
	$N_len += ($seq=~s/N/N/g);
	$total_len += length($seq);
	my $l=length($seq);
}

print OUT "Name\tTotal_length\tEffective_length\tN_length\tGC_length\tGC_rate\n";
$GC_len=$G_len+$C_len;
$eff_len=$total_len-$N_len;
$GC_rate=$GC_len/$eff_len*100;
$GC_rate=sprintf("%.2f",$GC_rate);
print OUT "Scaffold.fa\t$total_len\t$eff_len\t$N_len\t$GC_len\t$GC_rate%\n";

close IN;
close OUT;

sub USAGE{
  my $usage=<<"USAGE";
Name:
$0 --Information of you whole file

Description:
You can use it to calculate total length, effective length, N length, GC length and GC rate of you file.

Usage:
  options:
  -file <must|file>    infile(*.fasta)
  -out  <must|file>     outfile(*.*)
  -h    Help

Example:
perl $0 -file ../../ plum_0630.scafSeq.FG -out info.txt

USAGE
  print $usage;
  exit;
 }	
