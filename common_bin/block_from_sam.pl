#!/usr/bin/perl -w
use strict;
use List::Util qw/max min/;

my $file = shift;
my %hash = ();

open IN, "< $file" or die $!;
while(my $line = <IN>){
	chomp $line;
	next if($line =~ /^@/);
	my ($ref, $start) = (split /\s+/, $line)[2,3];
	$hash{$ref}{$start} = $start + 100
}
close IN;

my ($start, $end) = (0,0);
foreach my $r(keys %hash){
	print "$r:";
	foreach my $s(sort{$a <=> $b} keys %{$hash{$r}}){
		if($s > $end){
			print "($start, $end) ";
			$start = $s;
			$end = $hash{$r}{$s};
		}else{
			$end = $end > $hash{$r}{$s} ? $end:$hash{$r}{$s};
		}
	}
	print "($start, $end) ";
	print "\n";
}
