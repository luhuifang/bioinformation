#!/usr/bin/perl -w
#luhuifang
#2015/8/11

use strict; 
use Getopt::Long;

my ($file1,$file2,$out);
GetOptions(
	"help|?"=>\&USAGE,
        "file1:s"=>\$file1,
	"file2:s"=>\$file2,
        "out:s"=>\$out,
);
&USAGE unless ($file1 && $file2 && $out);	

open FILE3,"< $file1" or die "$!";
open FILE4,"< $file2" or die "$!";
open OUTCDS,"> $out " or die "$!";
my(%sequence)=();
$/=">";<FILE3>;$/="\n";
while(<FILE3>){
	my $head=$_;
	my $key=$1 if ($head=~/^(\S+)\s+/);
	$/=">";
	my $seq=<FILE3>;
	$seq=~s/\s+//g;
	$sequence{$key}=$seq;
	$/="\n";
}
my %cutCDS=();
my ($ID,$cds,$strand);
my $start=0;
while(<FILE4>){
	chomp;
	my @info_gff=split(/\s+/,$_);
	if(/mRNA/){
		$_=~/(\s+)ID=(\S+);[a-zA-Z]+.*/;
                $ID=$2;
		$strand=$info_gff[6];
		$cutCDS{$ID}{strand}=$strand;
		$start=0;
	}elsif(/CDS/){
		$cds=substr($sequence{$info_gff[0]},$info_gff[3]-1,$info_gff[4]-$info_gff[3]+1);
		if($info_gff[4] <= $start){
			$cutCDS{$ID}{seq}=$cds.$cutCDS{$ID}{seq};
		}else{
			$cutCDS{$ID}{seq}.=$cds;
		}
		$start=$info_gff[3];
	}

}
foreach my $key(keys %cutCDS){
	if($cutCDS{$key}{strand} eq "-"){
		$cutCDS{$key}{seq}=~tr/ATGC/TACG/;
		$cutCDS{$key}{seq}=reverse($cutCDS{$key}{seq});
	}
	print OUTCDS ">$key\n";
	my @seq=&line($cutCDS{$key}{seq},60);
	print OUTCDS "$_\n" for (@seq);
}

close FILE4;
close OUTCDS;
close FILE3;

sub line{
        my ($seq,$width)=@_;
        my @line=$seq=~/.{$width}/g;
        my $n=length($seq)%$width;
        my $last=substr($seq,length($seq)-$n,$n);
        push(@line,$last);
        @line;
}

sub USAGE{
  my $usage=<<"USAGE";
Name:
$0 --Cut CDS

Description:
You can use it to cut CDS, while infiles are *.fasta and *.gff.

Usage:
  options:
  -file1 <must|file>    infile(*.fasta)
  -file2 <must|file>	infile(*.gff)
  -out  <must|file>     outfile(*.fasta | *.*)
  -h    Help

Example:
perl $0 -file1 ../../plum_0630.scafSeq.FG -file2 ../../Prunus_mume_scaffold.gff -out CDS.fasta

USAGE
  print $usage;
  exit;
 }
