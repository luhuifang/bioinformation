#!/usr/bin/perl -w
use strict;
use File::Basename;
use Getopt::Long;

=head1 Author

 Author:Luhuifang  
 Email:luhuifang@genomics.cn
 Data:2015-12-17

=head1 Options

 -file		<file>		Target file
 -target	<int>		Which column in your target file is your target gene id 	
 -list		<file>		List of fpkm file or file contain messages you want to get
 -fc		<int>		Which column you want to get
 -help		

=head1 Usage

 perl get_message.pl -file ./example/importantGene_C.txt -list ./example/geneDiff.lst -fc 8 -target 4 >importantGene_C.txt.geneDiff.xls

=cut
my($file,$fpkm_list,$fc,$gene_c,$help);
GetOptions(
	"file:s"=>\$file,
	"list:s"=>\$fpkm_list,
	"fc:i"=>\$fc,
	"target:i"=>\$gene_c,
	"help|?"=>\$help,
);
die `pod2text $0` unless ($file && $fpkm_list && $fc && $gene_c);

my %gene_fpkm=();
foreach my $fpkm_file(`cat $fpkm_list`){
	open FPKM,"<$fpkm_file" or die $!;
	my $sample=fileparse($fpkm_file, qr/\..*/);
	chomp $sample;
	my $head=<FPKM>;
	while(my $fpkm_line=<FPKM>){
		chomp $fpkm_line;
		my ($gene_name,$fpkm_value)=(split /\s+/,$fpkm_line)[0,$fc-1];
		$gene_fpkm{$sample}{$gene_name}=$fpkm_value;
	}
	close FPKM;
}

open IN,"<$file" or die $!;
print "GO\tFunction\tevalue\tgene\t";
foreach my $key(sort {$a cmp $b} keys %gene_fpkm){
	print "$key\t";
}
print "\n";

while(my $fline=<IN>){
	chomp $fline;
	my $target_gene=(split /\t/,$fline)[$gene_c-1];	
	print "$fline\t";
	foreach my $key(sort {$a cmp $b} keys %gene_fpkm){
		$gene_fpkm{$key}{$target_gene} ||="--";
		print "$gene_fpkm{$key}{$target_gene}\t";
	}
	print "\n";
}
close IN;
