#!/usr/bin/perl -w
#luhuifang
#2015/8/10

use strict;
use Getopt::Long;

my $in;
GetOptions(
	"help|?"=>\&USAGE,
	"file:s"=>\$in,   
);
&USAGE unless ($in);
   
open IN, "< $in" or die "$!";

my %sequence=();
my ($n50,$n90,$scaf_n50,$scaf_n90);
while(<IN>){
	$_=~/>(\S+)\s+/;
	my $seq=<IN>;
	chomp($seq);
	$sequence{$1}=length($seq);
}
($n50,$scaf_n50)=&N50andN90(0.5,%sequence);
($n90,$scaf_n90)=&N50andN90(0.9,%sequence);

print "n50 is $scaf_n50 $n50\nn90 is $scaf_n90 $n90\n";

close IN;

#calculate n50 and n90, the arguments are a scalar(0.5 or 0.9) and an array(sequences)
sub N50andN90{
	my ($total_len,$add_len)=(0,0);
        my($ratio,%length)=@_;
		foreach my $key (keys %length){
		$total_len += $length{$key};
		}
        foreach my $len(sort{$length{$b} <=> $length{$a}} keys %length){
                $add_len += $length{$len};
                if($add_len >= ($total_len * $ratio)){return ($length{$len},$len);}
        }
}

sub USAGE{
  my $usage=<<"USAGE";
Name:
$0 --Calculate N50 and N90 of you file

Description:
You can use it to calculate N50 and N90 of you contigs or scaffolds. Your file should be *.fasta, and result will print on the screen.

Usage:
  options:
  -file <must|file>    infile(*.fasta)
  -h    Help

Example:
perl $0 -file ../../plum_0630.scafSeq.FG 

USAGE
  print $usage;
  exit;
 }
