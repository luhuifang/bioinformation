#!/usr/bin/perl -w
use strict;

=head1 Description

  This program is used for nucmer alignment. You can use it to alignment two genome sequences. 
  First the program cut two genome into small files, you can specify the number of small files.
  Then small files alignment one-to-one.

=head1 Version

  Author: Luhuifang luhuifang@genomics.cn
  Date: 2016-09-19
  Update: 2016-10-23

=head1 Usage

  Options:
    
    -ref	reference genome file
    -query	query genome file
    -cutref	the number of reference file cutted into [default: 1] 
    -cutquery	the number of query file cutted into [default: 1]
    -o		output path
    -P		set job's project
    -q		bind job to queue(s)
    -v		request the given resources [default: 17]
    -help	help message

=head1 Example

  perl auto_nucmer.pl -ref ref.fa -query query.fa -cutref 4 -cutquery 20 -o ./result -q gpu.q

=cut

use Getopt::Long;
use FindBin qw($Bin);
use File::Basename;

my ($ref, $query, $cutref, $cutquery, $outpath, $P, $q, $v, $help);
GetOptions(
	"ref:s" => \$ref,
	"query:s" => \$query,
	"cutref:i" => \$cutref,
	"cutquery:i" => \$cutquery,
	"o:s" => \$outpath,
	"P:s" => \$P,
	"q:s" => \$q,
	"v:i" => \$v,
	"help|?" => \$help,
);
die `pod2text $0` if (!$ref or !$query or !$q or $help);

$cutref ||= 1;
$cutquery ||= 1;
$v ||= 17;

my $qub_parse = "-q $q ";
$qub_parse .= " -P $P " if ($P);

my $currentpath = `pwd`;
chomp $currentpath;
$ref = "$currentpath/$ref" if ($ref !~ /^\//);
$query = "$currentpath/$query" if ($query !~ /^\//);

my $refbase = basename ($ref);
my $querybase = basename ($query);

## mkdir result file
$outpath ||= "./result";
mkdir $outpath unless (-e $outpath);

## cut ref file and query file
print "Cut ref file and query file!\n";
system("perl $Bin/../fastaDeal.pl --cutf $cutref $ref");
system("perl $Bin/../fastaDeal.pl --cutf $cutquery $query");
print "Cut files done!\n";

## generate nucmer.sh
print "Generate nucmer.sh!\n";
open NUCMER, "> nucmer.sh" or die $!;
foreach my $subref (`ls ./$refbase.cut/`){
	chomp $subref;
	my $refbasename = basename ($subref);

	foreach my $subquery (`ls ./$querybase.cut/`){
		chomp $subquery;
		my $querybasename = basename ($subquery);

		print NUCMER "/ifshk5/PC_PA_US/USER/shichch/bin/MUMmer3.23/nucmer -p $outpath/$refbasename.$querybasename $currentpath/$refbase.cut/$subref $currentpath/$querybase.cut/$subquery\n";
	}
}
close NUCMER;
print "Done!\n";

print "Run nucmer.sh!\n";
system ("perl $Bin/../qsub_jobs.pl -v $v -q '$qub_parse' -j nucmer nucmer.sh ");
print "Done!\n";

print "Process result!\n";
chdir $outpath;
open WORK, "> work.sh" or die $!;
print WORK "echo -e \"$ref $query\\nNUCMER\" > all.delta.lst\n";
print WORK "cat *.delta | grep -v $refbase | grep -v NUCMER >> all.delta.lst\n";
print WORK "mv all.delta.lst all.delta\n";
print WORK "/ifshk5/PC_PA_US/USER/shichch/bin/MUMmer3.23/delta-filter -i 80 all.delta > all.delta.filter\n";
print WORK "/ifshk5/PC_PA_US/USER/shichch/bin/MUMmer3.23/show-coords -r -l -H -d all.delta.filter > all.delta.filter.coords\n";
print WORK "perl $Bin/process_coord_query.pl all.delta.filter.coords \n";
print WORK "perl $Bin/process_coord_ref.pl all.delta.filter.coords \n";
close WORK;

system ("qsub -l vf=15G -cwd $qub_parse work.sh ");
print "Done!\n";

