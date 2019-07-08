#!/usr/bin/perl -w
use strict;

die "perl $0 <coords file> <seq_len file> > <result>\n" if (@ARGV != 2);

my $coord_file = shift;
# 1     3018  |        1     3018  |     3018     3018  |   100.00  |  1  1  scaffold1     scaffold1

my $len = shift;
my %seq_len=();

open LEN, "< $len" or die $!;
while(my $eachlen = <LEN>){
        chomp $eachlen;
        my ($scaffold, $length) = (split /\s+/, $eachlen)[0, 1];

#       $scaffold = quotemeta $scaffold;
        $scaffold =~ s/\|//g;
        $seq_len{$scaffold} = $length;
}
close LEN;

my %merge = ();
open COORD, "< $coord_file" or die $!;
while(my $line = <COORD>){
        chomp $line;
        $line =~ s/^\s*//;
        $line =~ s/\|//g;

        my ($Rstart, $Rend, $Ref, $Query) = (split /\s+/, $line)[0, 1, 11, 12];

#       print "$Rstart, $Rend, $Ref, $Query\n";

        ($Rstart, $Rend) = ($Rend, $Rstart) if ($Rstart > $Rend);

        if ($Ref ne $Query ){
                $merge{$Ref}{block_info}{$Query} +=1;
                $merge{$Ref}{block}{"$Rstart,$Rend"} = $Rstart;
        }

}
close COORD;

### print result ############

print "ID\tLength\tAlignment_len\tPercent\tBlock\n";

foreach my $key (sort {$a cmp $b} keys %merge){

        my $align_len = &SumLen( %{$merge{$key}{block}} );
        my $percent = $align_len/$seq_len{$key};

        print "$key\t$seq_len{$key}\t$align_len\t$percent\t";

        foreach my $q (sort {$a cmp $b} keys %{$merge{$key}{block_info}}){

                print "$q,$merge{$key}{block_info}{$q}; ";
        }

        print "\n";
}


######################################################
####################### Sub ###########################
#######################################################
sub SumLen{
        my (%block) = @_;
        my $sumlen;
        my ($start, $end) = (0, 0);

        foreach my $key (sort {$block{$a} <=> $block{$b}} keys %block){  ## sort by start

                my ($block_start, $block_end) = (split /,/,$key)[0,1];

                if( ($start < $block_start && $block_start < $end) && ( $block_end > $end )){  ## overlap
                        $sumlen += ( $block_end - $end );
                        $end = $block_end;

                }elsif( $block_start > $end ){  ## no overlap
                        $sumlen += ( $block_end - $block_start + 1);
                        $start = $block_start;
                        $end = $block_end;

                }
        }
        return $sumlen;
}
