#!/usr/bin/perl -w
use strict;

die "perl $0 <gff_file> <fasta_file> > <result.cds.fa>\n" if (@ARGV < 2);

my $gff = shift;
my $fasta = shift;

#============ Read fasta file ======================
my %sequence = ();
open FASTA, "< $fasta" or die $!;
$/ = ">"; <FASTA>; $/ = "\n";

while(my $tmp = <FASTA>){
	my $head = (split /\s+/, $tmp)[0];
	$/ = ">";
	
	my $seq = <FASTA>;
	$seq =~ s/\n//g;
	$sequence{$head} = $seq;
	
	$/ = "\n";
}
close FASTA;

#=========== Read gff file ============================
my %result_cds = ();
open GFF, "< $gff" or die $!;

while(my $eachline = <GFF>){
	my ($chr, $type, $start, $end, $strand, $info) = (split /\s+/, $eachline)[0,2,3,4,6,8];
	
	if($type eq "mRNA"){
		my $ID = $1 if ($info =~ /.*ID=(\S+);/);
		$result_cds{$ID}{strand} = $strand;

	}elsif($type eq "CDS"){
		my $parent = $1 if ($info =~ /.*Parent=(\S+);/);
		my $cds = substr($sequence{$chr}, $start-1, $end-$start+1);
		$result_cds{$parent}{seq} .= $cds;
	}
}
close GFF;

#========= Print result =============================
foreach my $key (keys %result_cds){
	
	if($result_cds{$key}{strand} eq "-"){
		$result_cds{$key}{seq} =~ tr/ATCG/TAGC/;
		$result_cds{$key}{seq} = reverse($result_cds{$key}{seq});
	}

	print ">$key\n";
	my @seq=&line($result_cds{$key}{seq},60);
	print "$_\n" for (@seq);
}

#=============== Sub =============================
sub line{
	my ($seq,$width)=@_;
	my @line=$seq=~/.{$width}/g;
	my $n=length($seq)%$width;
	my $last=substr($seq,length($seq)-$n,$n);
	push(@line,$last);
	@line;
}

