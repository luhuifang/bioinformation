#!/usr/bin/perl -w
use strict;

=head1 Name

 auto_tophat_cufflinks.pl --Auto to run Tophat, Cufflinks and Cuffmerge.

=head1 Description

 To this procedure, you must give it a input file which format will be like : sample    reads path.
 And you also need give it a reference genome sequence.

=head1 Version

 Author: Luhuifang
 E-mail: luhuifang@genomics.cn
 Data: 2016-06-03

=head1 Options

 -input         <must|file>     a file which format will be like : sample    reads path
 -ref           <must|str>      reference genome sequence
 -gff           <str>           reference gff file
 -qual          <str>           the quality of reads [--solexa-quals | --phred64-quals]
                                default: --phred64-quals
 -step          <str>           you can chose to run which step:
                                step 1: Tophat
                                step 2: Cufflinks
                                step 3: Cuffmerge
                                default: 123
 -outdir        <str>           you result's path, default: ./
 -q             <str>           set the queue name for qsub, like ' -q st.q -P F15ZQSQS2015'
 -help          <help>          help message

=head1 Example

 perl auto_tophat_cufflinks.pl -input info.lst -ref /ifshk5/PC_PA_US/PMO/F14FTSSCKF0222_PLAkqjR/15.annotation/canu_sspace/00.data/Hbr.final.scaffolds.fa -qual --phred64-quals -step 12 -outdir ./ -q ' -q st.q -P F15ZQSQS2015'

=cut

use FindBin qw($Bin);
use File::Basename;
use Getopt::Long;
use lib "$Bin/../lib";

my ($input, $ref, $gff, $qual, $step, $outdir, $q, $help);
GetOptions(
        "input:s"=>\$input,
        "ref:s"=>\$ref,
        "gff:s"=>\$gff,
        "qual:s"=>\$qual,
        "step:s"=>\$step,
        "outdir:s"=>\$outdir,
        "q:s"=>\$q,
        "help|?"=>\$help,
);
die `pod2text $0` unless ($input && $ref);

my $nowdir = `pwd`;
chomp $nowdir;
$step ||= "123";
$qual ||= "--phred64-qual";

if($outdir && $outdir !~ /^\//){
        $outdir="$nowdir/$outdir";
}elsif( !$outdir){
        $outdir=$nowdir;
}

if($gff && $gff !~ /^\//){
        $gff="$nowdir/$gff";
}

my $baseref = basename $ref;
$baseref =~ s/fasta$/fa/ if ($baseref =~ /fasta$/);

#----Step 1: Run tophat----#
if($step=~/1/){
########bowtie2 index
        mkdir "$outdir/00.Index" or die $!;
        `ln -s $ref $outdir/00.Index/$baseref`;
        open INDEX, ">$outdir/00.Index/index.sh" or die $!;
        print INDEX "/ifshk5/PC_PA_US/USER/shichch/bin/bowtie2-2.2.8/bowtie2-build $outdir/00.Index/$baseref $outdir/00.Index/$baseref\n";
        close INDEX;

        chdir "$outdir/00.Index/";
#       system("qsub -l vf=3G -cwd $q index.sh");
        chdir $nowdir;

########Tophat
        mkdir "$outdir/01.tophat/" or die $!;
        my %sample_reads=();

########read input file
        open IN, "<$input" or die $!;
        while(my $lines=<IN>){
                chomp $lines;
                my ($sample, $reads)=(split /\s+/,$lines)[0,1];
                $sample_reads{$sample} .= " $reads";
        }
        close IN;

########write tophat.sh and run
        open TOPHAT, ">$outdir/01.tophat/Tophat.sh" or die $!;
        foreach my $key (keys %sample_reads){
                if($gff){
                        print TOPHAT "/ifshk5/PC_PA_US/USER/shichch/bin/tophat-2.1.1.Linux_x86_64/tophat2 --max-intron-length 100000 -m 1 -r 20 $qual --mate-std-dev 20 --coverage-search --microexon-search -p 16 -G $gff -o $outdir/01.tophat/$key/ $outdir/00.Index/$baseref $sample_reads{$key}\n";

                }else{
                        print TOPHAT "/ifshk5/PC_PA_US/USER/shichch/bin/tophat-2.1.1.Linux_x86_64/tophat2 --max-intron-length 100000 -m 1 -r 20 --phred64-quals --mate-std-dev 20 --coverage-search --microexon-search -p 16 -o $outdir/01.tophat/$key/ $outdir/00.Index/$baseref $sample_reads{$key}\n";
                }
        }
        close TOPHAT;

        chdir "$outdir/01.tophat/";
#       system("nohup perl $Bin/qsub_jobs.pl -q $q -j Tophat -v 3 Tophat.sh &");
        chdir $nowdir;

########write tophat results to cufflinks.lst
        open OUT, ">cufflinks.lst" or die $!;
        foreach my $result(keys %sample_reads){
                print OUT "$result\t$outdir/01.tophat/$result/accepted_hits.bam\n";
        }
        close OUT;
}

#----Step 2: Run Cufflinks----#
if($step=~/2/){
########write cufflinks shell
        mkdir "$outdir/02.Cufflinks" or die $!;
        open CUFFLINKS, ">$outdir/02.Cufflinks/cufflinks.sh" or die $!;
        open LST, "< $nowdir/cufflinks.lst" or die $!;
        while(my $line=<LST>){
                chomp $line;
                my ($samples, $bam)=(split /\s+/,$line)[0,1];
                print CUFFLINKS "/ifshk4/BC_PUB/biosoft/pipe/bc_ba/software/Cufflinks/cufflinks-2.0.2.Linux_x86_64/cufflinks -p 8 -o $outdir/02.Cufflinks/$samples/ $bam\n";
        }
        close LST;
        close CUFFLINKS;

########run cufflinks
        chdir "$outdir/02.Cufflinks";
#       system("nohup perl $Bin/qsub_jobs.pl -q $q -j cufflinks -v 3 cufflinks.sh &");
        chdir $nowdir;

########write cufflinks results to assemblines.txt
        open OUT, ">assemblines.txt" or die $!;
        foreach my $results(`ls $outdir/02.Cufflinks/*/transcripts.gtf`){
                print OUT "$results\n";
        }
        close OUT;
}

#----Step 3: Run Cuffmerge----#
if($step=~/3/){
########write cuffmerge shell
        mkdir "$outdir/03.Cuffmerge";
        open CUFFMERGE, ">$outdir/03.Cuffmerge/merge.sh" or die $!;
        if($gff){
                print CUFFMERGE "/ifshk4/BC_PUB/biosoft/pipe/bc_ba/software/Cufflinks/cufflinks-2.0.2.Linux_x86_64/cuffmerge -s $outdir/00.Index/$baseref -g $gff -p 8 -o $outdir/03.Cuffmerge/merge/ $nowdir/assemblines.txt\n";
        }else{
                print CUFFMERGE "/ifshk4/BC_PUB/biosoft/pipe/bc_ba/software/Cufflinks/cufflinks-2.0.2.Linux_x86_64/cuffmerge -s $outdir/00.Index/$baseref -p 8 -o $outdir/03.Cuffmerge/merge/ $nowdir/assemblines.txt\n";
        }

########run cuffmerge
        chdir "$outdir/03.Cuffmerge";
#       system("nohup perl $Bin/qsub_jobs.pl -q $q -j cuffmerge -v 3 merge.sh &");
        chdir $nowdir;
}

