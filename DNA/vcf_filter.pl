#!/usr/bin/perl -w

=head1 Name

 vcf_filter.pl  --Filter data which is vcf file

=head1 Description

 The main funtion is filter data which is not meet the conditions.
 You can setup parameters including max depth, min depth, quality and distence of two neighbouring variation.

=head1 Version

  Author:luhifang luhuifang@genomics.cn
  Date:2015-08-26

=head1 Usage
  Options:
    -file	<must|file>	input file should be *.vcf
    -max	<integer>	max depth
    -min	<integer>	min depth
    -qual	<integer>	quality
    -dis	<integer>	distence of two neighbouring variation
    -h		<help>

=head1 Example
  perl vcf_filter.pl -file HiSeq.vcf.test -max 100 -min 3 -qual 100 -dis 1	
  perl vcf_filter.pl -file HiSeq.vcf.test -max 100 -min 3
  perl vcf_filter.pl -file HiSeq.vcf.test -max 100 
  perl vcf_filter.pl -file HiSeq.vcf.test -qual 100
  perl vcf_filter.pl -file HiSeq.vcf.test

=cut

use strict;
use Getopt::Long;
my ($file,$max,$min,$qual,$dis,$help);
GetOptions(
	"file=s"=>\$file,
	"max=i"=>\$max,
	"min=i"=>\$min,
	"qual=i"=>\$qual,
	"dis=i"=>\$dis,
	"help|?"=>\$help,
);
die `pod2text $0` unless ($file);

open IN,"< $file" or die $!;

my $maxDp=$max? $max:0;
my $minDp=$min? $min:0;
my $Q=$qual? $qual:0;
my $d=$dis? $dis:-1;
#print "$maxDp\t$minDp\t$Q\t$d\n";
my ($dp,$pos)=(0,0);
while(<IN>){
	chomp;
	if(/^#/){
		print "$_\n";
	}else{
		my @vcfinfo=split(/\s+/,$_);
		$_=~/.*DP=(\d+);.*/;
		$dp=$1;
		if(($dp <= $maxDp || $maxDp == 0) && $dp >= $minDp && ($vcfinfo[1]-$pos)>$d && $vcfinfo[5]>$Q){
			print "$_\n";
			$pos=$vcfinfo[1];
		}
	}
}

close IN;
