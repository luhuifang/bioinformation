#!/usr/bin/perl -w
use strict;

#update 2016-10-23

die "perl $0 <coords file>\n" if (@ARGV != 1);

my $coord_file = shift; 
# 1     3018  |        1     3018  |     3018     3018  |   100.00  |  1  1  scaffold1     scaffold1

my %Rmerge = ();
my %Rlen = ();

open COORD, "< $coord_file" or die $!;
while(my $line = <COORD>){
	chomp $line;
	$line =~ s/^\s*//;
	$line =~ s/\|//g;

	my ($Rstart, $Rend, $Qstart, $Qend, $Rlen, $Qlen, $Ref, $Query) = (split /\s+/, $line)[0, 1, 2, 3, 7, 8, 11, 12];
	
#	print "$Rstart, $Rend, $Ref, $Query\n";

	($Rstart, $Rend) = ($Rend, $Rstart) if ($Rstart > $Rend);
	($Qstart, $Qend) = ($Qend, $Qstart) if ($Qstart > $Qend);

	if ($Ref ne $Query ){

		$Rlen{$Ref} = $Rlen unless (exists $Rlen{$Ref});
		$Rmerge{$Ref}{block_info}{$Query}{"$Qstart\t$Qend"} = $Qstart;
		$Rmerge{$Ref}{block}{"$Rstart\t$Rend"} = $Rstart;
		
	}

}
close COORD;
### print result ############

### for ref #########
open RCOVER, "> Ref.coverage.txt" or die $!;
open RBLOCK, "> Ref.align.arrange.lst" or die $!;

print RCOVER "ID\tLength\tAlignment_len\tPercent\tBlock_len\tBlocks\n";

foreach my $Rkey (sort {$a cmp $b} keys %Rmerge){
	
	my ($align_len, $arr) = &SumLen($Rkey, %{$Rmerge{$Rkey}{block}});

	print RBLOCK "$arr";

	my $percent = $align_len/$Rlen{$Rkey};

	print RCOVER "$Rkey\t$Rlen{$Rkey}\t$align_len\t$percent\t";

	my $block_len = 0;
	my @Block = ();
	foreach my $q (sort {$a cmp $b} keys %{$Rmerge{$Rkey}{block_info}}){

		push(@Block, $q);
		my ($tmp_len, $b) = &SumLen($q, %{$Rmerge{$Rkey}{block_info}{$q}});
		$block_len += $tmp_len;

	}
	print RCOVER "$block_len\t@Block\n";
	
	delete $Rmerge{$Rkey};
	delete $Rlen{$Rkey};

}
close RCOVER;
close RBLOCK;

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

