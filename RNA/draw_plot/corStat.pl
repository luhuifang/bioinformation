#!/usr/bin/perl -w

=pod
description: correlation statistics
author: Zhang Fangxian, zhangfx@genomics.cn
created date: 20100528
modified date: 20101122, 20100713, 20100607, 20100605, 20100531
=cut

use strict;
use Getopt::Long;

my($data, $xcol, $ycol, $xlab, $ylab, $output, $help);

GetOptions("data:s" => \$data, "xcol:i" => \$xcol, "ycol:i" => \$ycol, "xlab:s" => \$xlab, "ylab:s" => \$ylab, "output:s" => \$output, "help|?" => \$help);
$xcol = 1 if (!defined $xcol);
$ycol = 2 if (!defined $ycol);
$output ||= "cor.pdf";

if (!defined $data || defined $help) {
	print STDERR << "USAGE";
description: correlation statistics
usage: perl $0 [options]
options:
	-data <file> *  data file
	-xcol <int>     column of x in data, default is 1
	-ycol <int>     column of y in data, default is 2
	-xlab <str>     x label
	-ylab <str>     y label
	-output <file>  output pdf file, default is "cor.pdf"

	-help|?         help information
e.g.: perl $0 -data AvsB.xls -xcol 2 -ycol 3 -xlab A -ylab B -output AvsB.cor.pdf
USAGE
	exit 1;
}

if(-e "/ifshk1"){
	open RCMD, "| /opt/blc/genome/biosoft/R/bin/R --no-save -q" || die $!;
}
else{
	open RCMD, "| /opt/blc/genome/biosoft/R/bin/R --no-save -q" || die $!;
}

print RCMD << "RCODE";
A <- read.table("$data", sep = "\\t", skip = 1)
B <- cor(A\$V$xcol, A\$V$ycol, method = c("spearman"))
C <- cor(A\$V$xcol, A\$V$ycol, method = c("pearson"))
linefit <-lm(A\$V$ycol ~ A\$V$xcol)
pdf("$output")
plot(A\$V$xcol, A\$V$ycol, xlab = "$xlab", ylab = "$ylab", type = "p", pch = ".",col = "dark red")
abline(lm(A\$V$ycol~A\$V$xcol),col= 1,lwd=0.5)
legend("topleft", c(paste("spearman r = ", B), paste("pearson r = ", C), paste("slope k = ", linefit\$coefficients[2])))
dev.off()
RCODE
close RCMD;

exit 0;
