#!/usr/bin/perl -w
use strict;

die "perl $0 <fasta> depth out_prefix\n" unless(@ARGV >= 3);
my $fa = shift;
my $depth = shift;
my $outprefix = shift;
my %seq = ();
my ($id, $chr_num, $len) = ("", 0, 0);

open IN,"<$fa" or die $!;
while(my $line = <IN>){
	chomp $line;
	if($line =~ /^>(\S+)\s/){
		$id = $1;
		$chr_num += 1;
	}else{
		$seq{$id} .= $line;
		$len += length($line);
	}

}
close IN;

my $qual = "F" x 100;
open OUTREAD, ">$outprefix.fq" or die $!;
open OUTBED, ">$outprefix.bed" or die $!;

my $read_num = int(($depth * $len)/100);
my $avg_overlap = int(($depth - 1)*$len/($read_num - $chr_num));

#my $minOverlap = 1 > ($avg_overlap - 30) ? 1:($avg_overlap - 30);
my $minOverlap = 1 ;
my $maxOverlap = $avg_overlap + 30;

my $start = 0;
for(my $i=0; $i<$read_num; $i++){
	foreach my $chr(keys %seq){
		if($start > (length($seq{$chr}) - 101)){
			my $read = substr($seq{$chr}, length($seq{$chr}) - 101, 100);
			print OUTREAD "\@$chr\_$i/1\n$read\n+\n$qual\n";
			print OUTBED "$chr\_$i\t$chr\t$start\n";

			$start = 0;
			last;
		}

		my $read = substr($seq{$chr}, $start, 100);
		print OUTREAD "\@$chr\_$i/1\n$read\n+\n$qual\n";
		print OUTBED "$chr\_$i\t$chr\t$start\n";

		my $overlap = int(rand($maxOverlap-$minOverlap) + $minOverlap + 1);
		$start = $start + 100 - $overlap;
	}
}
close OUTREAD;
close OUTBED;
