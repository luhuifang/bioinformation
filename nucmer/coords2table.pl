#!/usr/bin/perl -w
use strict;

die "perl $0 <coords file> > <result>\n" if (@ARGV != 1);

my $coord_file=shift;

my %len = ();
my %merge = ();

open COORD,"< $coord_file" or die $!;
while(<COORD>){
        chomp;
        s/^\s*//;
        s/\|//g;
        my ($Rstart, $Rend, $Qstart, $Qend, $Rlen, $Qlen, $Ref, $Query) = (split /\s+/,$_)[0, 1, 2, 3, 7, 8, 11, 12];

        ($Rstart, $Rend) = ($Rend, $Rstart) if ($Rstart > $Rend);
        ($Qstart, $Qend) = ($Qend, $Qstart) if ($Qstart > $Qend);

        $len{$Ref} ||= $Rlen;
        $len{$Query} ||= $Qlen;

        if ($Ref ne $Query ){
                $merge{$Ref}{$Query}{block_num} += 1;
                $merge{$Ref}{$Query}{R_block}{"$Rstart,$Rend"} = $Rstart;
                $merge{$Ref}{$Query}{Q_block}{"$Qstart,$Qend"} = $Qstart;
        }
}
close COORD;

### print result ####

print "Ref\tRef_len\tRef_alig_len\tRef_percent\tQuery\tQuery_len\tQuery_alig_len\tQuery_percent\tBlock_num\n";

foreach my $r (sort {$a cmp $b} keys %merge){
        foreach my $q (sort {$a cmp $b} keys %{$merge{$r}}){

                $merge{$r}{$q}{R_alig_len} = &SumLen( %{$merge{$r}{$q}{R_block}} );  ## Length of alignment
                $merge{$r}{$q}{Q_alig_len} = &SumLen( %{$merge{$r}{$q}{Q_block}} );

                my $R_percent = $merge{$r}{$q}{R_alig_len} / $len{$r};
                my $Q_percent = $merge{$r}{$q}{Q_alig_len} / $len{$q};

                print "$r\t$len{$r}\t$merge{$r}{$q}{R_alig_len}\t$R_percent\t$q\t$len{$q}\t$merge{$r}{$q}{Q_alig_len}\t$Q_percent\t$merge{$r}{$q}{block_num}\n";
        }
}

######################################################
###################### Sub ###########################
######################################################
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
