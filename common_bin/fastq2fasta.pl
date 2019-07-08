#!/usr/bin/perl -w
use strict;
use File::Basename;

die "perl $0 <fq_file> qual out_dir\n" unless (@ARGV>=3);
my $fq = shift;
my $qualsystem = shift;
my $outdir = shift;

my @suffixlist = qw(.fastq .fq .fq1 .fq2);
my ($basename, $parpath, $suffix) = fileparse($fq, @suffixlist);
open FQ, "< $fq" or die $!;
open FA, ">> $outdir/$basename.fa" or die $!;
open QUAL, ">> $outdir/$basename.fa.qual" or die $!;
while(my $readsname = <FQ>){
	my $seq = <FQ>;
	my $info = <FQ>;
	my $qual = <FQ>;
	$readsname =~ s/@/>/;
	print FA "$readsname$seq";

	print QUAL "$readsname";
	chomp $qual;
	my @quallist = split("", $qual);
	foreach my $q(@quallist){
		my $ordq = ord($q) - $qualsystem;
		print QUAL "$ordq ";
	}
	print QUAL "\n";
}

close FQ;
close FA;
close QUAL;

