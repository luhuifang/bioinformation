#!/usr/bin/perl
use strict;
use File::Basename;
my$RPO=$ARGV[0];my %hasha; my%hashb;my%hashc;
open FIL,"$RPO" or die $!;
while(<FIL>){
	chomp;
	split/\s+/;
	$hasha{$_[0]}=$_[4];
	$hashc{$_[0]}++;
}
my $RPT=$ARGV[1];
open RPT,"$RPT" or die $!;
while(<RPT>){
	chomp;
	split/\s+/;
	$hashb{$_[0]}=$_[4];
	$hashc{$_[0]}++;
}

my $na1=basename($RPO);
$na1=~s/\.Gene\.rpkm\.xls/-RPKM/g;
my$na2=basename($RPT);
$na2=~s/\.Gene\.rpkm\.xls/-RPKM/g;

print "GeneID\t$na1\t$na2\n";
foreach my$key(keys %hashc){
		chomp;
		unless(exists $hasha{$key}){
			$hasha{$key}=0.0001;
		}
		unless(exists $hashb{$key}){
				$hashb{$key}=0.0001;
		}
				
		printf "%s\t%5.2f\t%5.2f",$key,$hasha{$key},$hashb{$key};
		printf "\n";
}

