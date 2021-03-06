#!/usr/bin/perl -w
use strict;

#update 2016-10-23

die "perl $0 <coords file>\n" if (@ARGV != 1);

my $coord_file = shift; 
# 1     3018  |        1     3018  |     3018     3018  |   100.00  |  1  1  scaffold1     scaffold1

my %Qmerge = ();

my %Qlen = ();

open COORD, "< $coord_file" or die $!;
while(my $line = <COORD>){
	chomp $line;
	$line =~ s/^\s*//;
	$line =~ s/\|//g;

	my ($Rstart, $Rend, $Qstart, $Qend, $Rlen, $Qlen, $Ref, $Query) = (split /\s+/, $line)[0, 1, 2, 3, 7, 8, 11, 12];
	
#	print "$Rstart, $Rend, $Ref, $Query\n";

	($Qstart, $Qend) = ($Qend, $Qstart) if ($Qstart > $Qend);
	($Rstart, $Rend) = ($Rend, $Rstart) if ($Rstart > $Rend);

	if ($Ref ne $Query ){
		
		$Qlen{$Query} = $Qlen unless (exists $Qlen{$Query});
		$Qmerge{$Query}{block_info}{$Ref}{"$Rstart\t$Rend"} = $Rstart;
		$Qmerge{$Query}{block}{"$Qstart\t$Qend"} = $Qstart;
	}

}
close COORD;

### print result ############

### for query ########
open QCOVER, "> Query.coverage.txt" or die $!;
open QBLOCK, "> Query.align.arrange.lst" or die $!;
print QCOVER "ID\tLength\tAlignment_len\tPercent\tBlock_len\tBlocks\n";

foreach my $Qkey (sort {$a cmp $b} keys %Qmerge){
	
	my ($align_len, $arr) = &SumLen($Qkey, %{$Qmerge{$Qkey}{block}});

	print QBLOCK "$arr";

	my $percent = $align_len/$Qlen{$Qkey};

	print QCOVER "$Qkey\t$Qlen{$Qkey}\t$align_len\t$percent\t";

	my $block_len = 0;
	my @Block = ();
	foreach my $q (sort {$a cmp $b} keys %{$Qmerge{$Qkey}{block_info}}){

		push (@Block, $q);
		my ($tmp_len, $b) = &SumLen($q,  %{$Qmerge{$Qkey}{block_info}{$q}});
		$block_len += $tmp_len;
		
	}
	print QCOVER "$block_len\t@Block\n";

	delete $Qmerge{$Qkey};
	delete $Qlen{$Qkey};

}
close QCOVER;
close QBLOCK;

######################################################
####################### Sub ###########################
#######################################################
sub SumLen{
	my ($marker, %block) = @_;
	my ($sumlen, $arrange);
	my ($start, $end, $n) = (0, 0, 0);

	my %arr = ();
	$arr{$n}{start} = $start;
	$arr{$n}{end} = $end;

	foreach my $key (sort {$block{$a} <=> $block{$b}} keys %block){  ## sort by start

		my ($block_start, $block_end) = (split /\t/,$key)[0,1];

		if( ($start <= $block_start && $block_start <= $end) && ( $block_end >= $end )){  ## overlap
			$sumlen += ( $block_end - $end );
			$end = $block_end;

			$arr{$n}{end} = $end;

		}elsif( $block_start > $end ){  ## no overlap
			$sumlen += ( $block_end - $block_start + 1);
			$start = $block_start;
			$end = $block_end;

			$n++;
			$arr{$n}{start} = $start;
			$arr{$n}{end} = $end;

		}
	}
	
	foreach my $num (sort {$arr{$a}{start} <=> $arr{$b}{start}} keys %arr){
		$arrange .= "$marker\t$arr{$num}{start}\t$arr{$num}{end}\n" if ($arr{$num}{start} != 0 && $arr{$num}{end} != 0);
	}

	return ($sumlen, $arrange);
}

