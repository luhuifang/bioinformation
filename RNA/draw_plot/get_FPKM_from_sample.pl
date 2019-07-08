#!/usr/bin/perl -w
use strict;
=head1 Name

 get_FPKM_from_sample.pl --Get FPKM from samples using blast_result.

=head1 Version

 Author:Luhuifang
 E-mail:luhuifang@genomics.cn
 Data:2015-12-01

=head1 Options

 -list		<must|file>	The list of blast_result_file <==>sample's FPKM file, file format will be:
				library_name	blast_result_file	fpkm_file 
 -bq		<int>		The cloumn which is query_id, which will be show in result, default=1
 -bs		<int>		The column which is subject_id, which is fpkm file's gene name, default=2
 -head		<0|1>		1:blast_file has header, 0:blast_file hasn't header, default=0
 -fc		<int>		The column which is fpkm value, default=5
 -transgene	<file>		The file convert gene_id to gene_name, file format:gene_id gene_name
 -transsample	<file>		The file convert sample_name to library_name, file format: library_name sample_name
 -help		<help>		Help message

=head1 Usage

 perl get_FPKM_from_sample.pl -list example/list.lst -bq 1 -bs 5 -head 1
 perl get_FPKM_from_sample.pl -list example/file -bq 1 -bs 5 -head 1 -fc 5 -transgene example/genename_gi.list -transsample example/lib-sample.txt > gene.FPKM.xls

=cut

use File::Basename;
use Getopt::Long;

my ($list,$bq,$bs,$head,$fc,$transgene,$transsample,$help);
GetOptions(
	"list:s"=>\$list,
	"bq:i"=>\$bq,
	"bs:i"=>\$bs,
	"head:i"=>\$head,
	"fc:i"=>\$fc,
	"transgene:s"=>\$transgene,
	"transsample:s"=>\$transsample,
	"help|?"=>\$help,
);
die `pod2text $0` unless ($list);

$bq ||= "1";
$bs ||= "2";
$fc ||= "5";
$head ||= "0";

#if transgene
my %transgene=();
if($transgene){
	foreach my $line(`cat $transgene`){
		chomp $line;
		my ($geneid,$genename)=(split /\s+/,$line)[0,1];
		$transgene{$geneid}=$genename;
	}
}

#if transsample
my %transsample=();
if($transsample){
	foreach my $sline(`cat $transsample`){
		chomp $sline;
		my ($lib,$samples)=(split /\s+/,$sline)[0,1];
		$transsample{$samples}=$lib;
	}
}

my %gene_fpkm=();
my @sample_list=();
foreach my $file (`cat $list`){
	chomp $file;
	my ($sample,$blastfile,$fpkmfile) = (split /\s+/,$file)[0,1,2];
	push (@sample_list,$sample);
	#read fpkm file
	open FPKM,"<$fpkmfile" or die $!;
	my %fpkm=();
	my $header2=<FPKM>;
	while(my $fpkmline=<FPKM>){
		my($gene_id,$fpkm)=(split /\s+/,$fpkmline)[0,$fc-1];
		$fpkm{$gene_id}=$fpkm;
	}

	#read blast file
	open BLAST, "<$blastfile" or die $!;
	my $header=<BLAST> if ($head == "1");
	while(my $blastline=<BLAST>){
		my($query_id,$subject_id)=(split /\s+/,$blastline)[$bq-1,$bs-1];
		if (exists $fpkm{$subject_id}){
			if(exists $transgene{$query_id}){
				$gene_fpkm{$transgene{$query_id}}{$sample}=$fpkm{$subject_id};
			}else{
				$gene_fpkm{$query_id}{$sample}=$fpkm{$subject_id};
			}
		}else{
			if(exists $transgene{$query_id}){
				$gene_fpkm{$transgene{$query_id}}{$sample}=0;
			}else{
				$gene_fpkm{$query_id}{$sample}=0;
			}
		}
	}
	close BLAST;
}

#print result
print "gene_id\t";
foreach my $samplename(@sample_list){
	if(exists $transsample{$samplename}){
		print "$transsample{$samplename}\t";
	}else{
		print "$samplename\t";
	}
}
print "\n";
foreach my $key (sort {$a cmp $b} keys %gene_fpkm){
	print "$key\t";
	foreach my $key1 (@sample_list){
		$gene_fpkm{$key}{$key1} ||= "NA";
		print "$gene_fpkm{$key}{$key1}\t";
	}
	print "\n";
}

