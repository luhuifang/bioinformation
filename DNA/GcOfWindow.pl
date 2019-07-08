#!/usr/bin/perl -w
#luhuifang
#2015/8/11

use strict;
use Getopt::Long;
my ($file,$out,$window,$step);
GetOptions(
        "help|?"=>\&USAGE,
        "file:s"=>\$file,
        "out:s"=>\$out,
        "bin=i"=>\$window,
        "step=i"=>\$step,
)or &USAGE;
&USAGE unless ($file && $out && $window && $step);

open IN, "< $file" or die "$!";
open OUT, "> $out" or die "$!";
my ($fragment,$GC,$N,$GC_rate);
while(<IN>){
	my $seq=<IN>;
	chomp;
	for (my $i=0; $i<=length($seq); $i+=$step){
		$fragment=substr($seq,$i,$window);
		$GC=($fragment=~s/C|G/C|G/g);
		$N=($fragment=~s/N/N/g);
		if($N == length($fragment)){
			$GC_rate=0;
		}else{
			$GC_rate=$GC/(length($fragment)-$N);
		}
		$GC_rate=sprintf ("%.3f",$GC_rate);
		print OUT "$GC_rate\n";
	}
}

close IN;
close OUT;

sub USAGE{
  my $usage=<<"USAGE";
Name:
$0 --Calculate GC content of bin

Description:
You can use it to calculate GC content of bin. You can set not only the length of bin but also the step.

Usage:
  options:
  -file <must|file>     infile(*.fasta)
  -out  <must|file>     outfile(*.*)
  -bin  <must|number>   length of window
  -step <must|number>   length of step
  -h    Help

Example:
perl $0 -file ../../plum_0630.scafSeq.FG -out GC.txt -bin 250 -step 250

USAGE
  print $usage;
  exit;
 }
