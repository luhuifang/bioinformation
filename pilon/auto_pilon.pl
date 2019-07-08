#!/usr/bin/perl -w
use strict;

=head1 Description

 This program is used to call consensus using NGS reads for a draft genome. It uses Pilon software to work.
 So, you should give it two input files: a fasta file of draft genome and a list file contain fq files of NGS reads.
 The program have three steps:
	step1: Build index of draft genome
	step2: Map reads to genome using BWA
	step3: Call consensus using Pilon
 You can skip some steps if you have done it.

=head1 Version

 Author: Luhuifang luhuifang@genomics.cn
 Date: 2016-10-08

=head1 Usage

 perl auto_pilon.pl [options] <genome file> <fq list file>
 
 Options:
 Common options:
	-out    <path>  The output dir path. [default:./]
        -l	<int>   The resource when qsub the job, it depends on the size of each small genome.
                        Try to allocate 1.5GB per megabase of input genome to be processed. [default:50]
	-step	<int>	Select which steps you want to run. [default:123]
	-q	<str>	Sqt job's queue
	-P	<str>	Set job's project

 For BWA: 
	-cutf	<int>	The number of files which you want cut genome into,
			it depends on the size of genome, and it relate to resource when qsub the job.
			For example, the size of genome is 1Gb, -cutf is 100, 
			and then each small file is 10Mb, the resource(vf) may be 15Gb. [default:1]
 For Pilon:
 OUTPUT:
	-changes	If specified, a file listing changes in the <output>.fasta will be generated.
	-vcf		If specified, a vcf file will be generated
	-vcfqe		If specified, the VCF will contain a QE (quality-weighted evidence) field rather
			than the default QP (quality-weighted percentage of evidence) field.
	-tracks		This options will cause many track files (*.bed, *.wig) suitable for viewing in
			a genome browser to be written.
 CONTROL:
	-chunksize
		<int>	Input FASTA elements larger than this will be processed in smaller pieces not to
			exceed this size (default 10000000).
	-diploid	Sample is from diploid organism; will eventually affect calling of heterozygous SNP
	-dumpreads	Dump reads for local re-assemblies.
	-duplicates	Use reads marked as duplicates in the input BAMs (ignored by default).
	-iupac		Output IUPAC ambiguous base codes in the output FASTA file when appropriate.
	-nonpf		Use reads which failed sequencer quality filtering (ignored by default).
	-threads
		<int>	Degree of parallelism to use for certain processing (default 1). Experimental.
	-verbose	More verbose output.	
	-debug		Debugging output (implies verbose).

=cut
	
use File::Basename;
use FindBin qw($Bin);
use Getopt::Long;

my ($out,$l,$step,$q,$P,$cutf,$changes,$vcf,$vcfqe,$tracks,$chunksize,$diploid,$dumpreads,$duplicates,$iupac,$nonpf,$threads,$verbose,$debug,$help);
GetOptions(
	'out:s'=>\$out,
	'l:i'=>\$l,
	'step:s'=>\$step,
	'q:s'=>\$q,
	'P:s'=>\$P,
	'cutf:i'=>\$cutf,
	'changes!'=>\$changes,
	'vcf!'=>\$vcf,
	'vcfqe!'=>\$vcfqe,
	'tracks!'=>\$tracks,
	'chunksize:i'=>\$chunksize,
	'diploid!'=>\$diploid,
	'dumpreads!'=>\$dumpreads,
	'duplicates!'=>\$duplicates,
	'iupac!'=>\$iupac,
	'nonpf!'=>\$nonpf,
	'threads:i'=>\$threads,
	'verbose!'=>\$verbose,
	'debug!'=>\$debug,
	'help|?'=>\$help,
);
die `pod2text $0` unless (@ARGV==2 && $q);

my $genome = shift;
my $fq_lst = shift;
my $qsub_pare = "-q $q ";
$qsub_pare .= "-P $P" if ( $P );

my $pilon_pare = "";
$changes ? $pilon_pare .= "--changes " : $pilon_pare .= "";
$vcf ? $pilon_pare .= "--vcf " : $pilon_pare .= "";
$vcfqe ? $pilon_pare .= "--vcfqe " : $pilon_pare .= "";
$tracks ? $pilon_pare .= "--tracks " : $pilon_pare .= "";
$chunksize ? $pilon_pare .= "--chunksize $chunksize " : $pilon_pare .= "";
$diploid ? $pilon_pare .= "--diploid " : $pilon_pare .= "";
$dumpreads ? $pilon_pare .= "--dumpreads " : $pilon_pare .= "";
$duplicates ? $pilon_pare .= "--duplicates " : $pilon_pare .= "";
$iupac ? $pilon_pare .= "--iupac " : $pilon_pare .= "";
$nonpf ? $pilon_pare .= "--nonpf " : $pilon_pare .= "";
$threads ? $pilon_pare .= "--threads $threads " : $pilon_pare .= "";
$verbose ? $pilon_pare .= "--verbose " : $pilon_pare .= "";
$debug ? $pilon_pare .= "--debug " : $pilon_pare .= "";

chomp( my $current_dir = `pwd`);

$out ||= $current_dir;
$l ||= "50";
$step ||= "123";
$cutf ||= "1";
$chunksize ||= "10000000";
$threads ||= "1";

$genome = "$current_dir/$genome" unless ($genome =~ /^\//);
$fq_lst = "$current_dir/$fq_lst" unless ($fq_lst =~ /^\//);

## Step1: Build index for BWA
if($step =~ /1/){
	mkdir "$out/01.Index";
	chdir "$out/01.Index";

	system("ln -s $genome input.genome.fa");
	system("perl $Bin/../fastaDeal.pl --cutf $cutf input.genome.fa");
	system("for i in \`ls input.genome.fa.cut/*\`; do mv \$i \$i.fasta;done");

	open INDEX, "> index.sh" or die $!;
	print INDEX "echo Step1 index: start at `date`\n";
	print INDEX "/opt/blc/genome/biosoft/bwa-0.6.2/bwa index -a bwtsw input.genome.fa\n";
	print INDEX "echo Step1 index: end at `date`\n";
	close INDEX;

	system("perl $Bin/../qsub_jobs.pl -l 100 -v 5 -q '$qsub_pare' -j index index.sh ");
}

## Step2: Run BWA
my $bam = "";

if($step =~ /2/){
	mkdir "$out/02.BWA";
	chdir "$out/02.BWA";

	my %fq = ();
	open LST, "< $fq_lst " or die $!;
	while(my $fq_line = <LST>){
		chomp $fq_line;
		my ($lib, $fqfile) = (split /\s+/, $fq_line)[0,1];
		push @{$fq{$lib}}, $fqfile;
	}
	close LST;

	foreach my $term (keys %fq){
		my $n = 0;
		my $sample = "";
		my $sai = "";
	
		open OUT, "> $term.bwa.sh" or die $!;
		print OUT "echo Step2 BWA: start at `date`\n";
	
		foreach my $each (@{$fq{$term}}){
			$n ++ ;
			print OUT "/opt/blc/genome/biosoft/bwa-0.6.2/bwa aln -o 1 -t 20 -q 10 $out/01.Index/input.genome.fa $each > $out/02.BWA/$term\_$n.sai\n";
			$sample .= "$each ";
			$sai .= "$out/02.BWA/$term\_$n.sai ";
		}

		if($n == 1){
			print OUT "/opt/blc/genome/biosoft/bwa-0.6.2/bwa samse -f $out/02.BWA/$term.sam $out/01.Index/input.genome.fa $sai $sample\n";
		}elsif($n == 2){
			print OUT "/opt/blc/genome/biosoft/bwa-0.6.2/bwa sampe -f $out/02.BWA/$term.sam $out/01.Index/input.genome.fa $sai $sample\n";
		}
	
		print OUT "/opt/blc/genome/biosoft/samtools-0.1.8/samtools view -uS $out/02.BWA/$term.sam > $out/02.BWA/$term.bam\n";
		print OUT "/opt/blc/genome/biosoft/samtools-0.1.8/samtools flagstat $out/02.BWA/$term.bam > $out/02.BWA/$term.bam.stat\n";
#		print OUT "/opt/blc/genome/biosoft/samtools-0.1.8/samtools sort -m 4000000000 $out/02.BWA/$term.bam $out/02.BWA/$term.sort\n";
#		print OUT "/opt/blc/genome/biosoft/samtools-0.1.8/samtools index $out/02.BWA/$term.sort.bam\n";
		print OUT "echo Step2 BWA: end at `date`\n";
		close OUT;

		$bam .= "--bam $out/02.BWA/$term.sort.bam ";
	}

	open BWA, "> bwa.sh " or die $!;
	foreach my $bwa(`ls $out/02.BWA/*.bwa.sh`){
		chomp $bwa;
		print BWA "sh $bwa\n";
	}
	close BWA;

#	system("perl $Bin/../qsub_jobs.pl -v 5 -q '$qsub_pare' -j bwa bwa.sh");
}

## Step3: Run pilon for calling consensus
if($step =~ /3/){
	mkdir "$out/03.Pilon";
	chdir "$out/03.Pilon";
	mkdir "result";

	open PILON, "> pilon.sh" or die $!;
	foreach my $small_file (`ls $out/01.Index/input.genome.fa.cut/`){
		chomp $small_file;
		print PILON "/ifshk5/PC_PA_US/USER/shichch/bin/pilon-1.20.jar --genome $out/01.Index/input.genome.fa.cut/$small_file $bam --output $small_file --outdir $out/03.Pilon/result $pilon_pare\n";
	}
	close PILON;

	system("perl $Bin/../qsub_jobs.pl -v $l -q '$qsub_pare' -j pilon pilon.sh");
}
