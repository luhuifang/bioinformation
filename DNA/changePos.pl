#£¡/usr/bin/perl -w
use strict;
use Getopt::Long;
my ($gfffile,$agpfile,$gffout);
GetOptions(
	"gfffile:s"=>\$gfffile,
	"agpfile:s"=>\$agpfile,
	"outfile:s"=>\$gffout,
	"help|?"=>\&USAGE,
);
&USAGE unless ($gfffile && $agpfile && $gffout);


open GFF, "< $gfffile" or die $!;
open AGP, "< $agpfile" or die $!;
open OUT1, "> $gffout" or die $!;
my($seq,@agp_info,@gff_info,$chr_start,$chr_end,$strand);
my %gene=();
my $n=0;
while(<AGP>){
	chomp;
	if($_!~/\s+N|U\s+/){												#not gap
		@agp_info=split (/\s+/,$_);		
		seek(GFF,0,0);					
		while(my $gff=<GFF>){ 
			chomp($gff);
			@gff_info=split (/\s+/,$gff);
			if($agp_info[5] eq $gff_info[0]){     #same sccaffold
				if($agp_info[8] eq "-"){            #orientation is -
					$chr_start=($agp_info[7]-$agp_info[6]+1)-($gff_info[4]-$agp_info[6]+1)+$agp_info[1];   #$agp_info[7]-$agp_info[6]+1 is total length of scaffold 
					$chr_end=($agp_info[7]-$agp_info[6]+1)-($gff_info[3]-$agp_info[6]+1)+$agp_info[1];     #total_length - pos_in_scaf + start_in_chr
					if($gff_info[6] eq "-"){$strand="+";}else{$strand="-";}					
				}else{
					$chr_start=($gff_info[3]-$agp_info[6]+1)+$agp_info[1]-1;   #$gff_info[3]-$agp_info[6]+1 is relative position of scaffold 
					$chr_end=($gff_info[4]-$agp_info[6]+1)+$agp_info[1]-1;     #pos_in_scaf + start_in_chr - 1
					if($gff_info[6] eq "+"){ $strand="+";}else{$strand="-";}	
				}
				print OUT1 "$agp_info[0]\t$gff_info[1]\t$gff_info[2]\t$chr_start\t$chr_end\t$gff_info[5]\t$strand\t$gff_info[7]\t$gff_info[8]\n";				
			}
		}
	}
}
close GFF;
close AGP;
close OUT1;

sub USAGE{
	my $usage=<<"USAGE";

Name:
$0 --CDSs' positions in scaffold convert to positions in chromosome

UASGE:
  options:
    -gfffile	<must|file>	input file that should be *.gff
    -agpfile	<must|file>	input file that should be *.agp
    -outfile	<must|file>	output file(*.gff or *.*)
    -h		<help>

Example:
perl $0 -gfffile chr13.scaffold.gff -agpfile chr13.agp -outfile chr_gene.gff

USAGE
	print "$usage";
	exit;
}
