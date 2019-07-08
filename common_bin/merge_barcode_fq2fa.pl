#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my ($barcode_list, $read1_dir, $read2_dir, $outdir, $help);
GetOptions(
	"list=s" => \$barcode_list,
	"1=s" => \$read1_dir,
	"2=s" => \$read2_dir,
	"o=s" => \$outdir,
	"h|?" => \$help,
);
die "perl $0 -list <barcode_list> -1 <read1_dir> -2 <read2_dir> -o <outdir>\n" if(!$barcode_list or !$read1_dir or !$read2_dir or !$outdir);

open LIST, "<$barcode_list" or die $!;
while(my $line = <LIST>){
	chomp $line;
	next if ($line !~ /^\d/);
	my $barcode = (split /\s+/, $line)[0];
	my ($b1, $b2, $b3) = (split /_/, $barcode)[0,1,2];
	my $read1 = "$read1_dir/$b1/$b2/$barcode.fq";
	my $read2 = "$read2_dir/$b1/$b2/$barcode.fq";
	next if (!-e $read1 or !-e $read2);
	my $outfa = "$outdir/$barcode.fa";
	&writeFq2Fa($read1, 33, $outfa);
	&writeFq2Fa($read2, 33, $outfa);
}
close LIST;

sub writeFq2Fa{
	my %fasta_hash = ();
	my ($fq, $qualsystem, $outf) = @_;
	open FQ,"<$fq" or die $!;
	open FA,">>$outf" or die $!;
	open QUAL, ">>$outf.qual" or die $!;
	while(my $readname = <FQ>){
		my $seq = <FQ>;
		my $info = <FQ>;
		my $qual = <FQ>;
		$readname =~ s/^@/>/;
		print FA "$readname$seq";

		print QUAL "$readname";
		chomp $qual;
		my @quallist = split("", $qual);
		foreach my $q(@quallist){
			my $ordq = ord($q) - $qualsystem;
			print QUAL "$ordq ";
		}
		print QUAL "\n";
	}
	close FQ;
	close FA;
	close QUAL;
}
