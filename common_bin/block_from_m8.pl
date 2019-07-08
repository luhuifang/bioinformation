#!/usr/bin/perl -w
use strict;

my $m8_file = shift;

my %block = ();
open M8, "< $m8_file" or die $!;
while(my $line = <M8>){
	chomp $line;
	my($name, $s, $e) = (split /\s+/, $line)[0,6,7];
	my $start = $s > $e ? $e:$s;
	my $end = $s > $e ? $s:$e;
	$block{$name}{$start}{$end} ++;
}
close M8;

foreach my $n(keys %block){
	foreach my $s(sort {$a <=> $b} keys %{$block{$n}}){
		foreach my $e(sort {$a <=> $b} keys %{$block{$n}{$s}}){
			print "$n\t$s\t$e\t$block{$n}{$s}{$e}\n";
		}
	}
}
	
