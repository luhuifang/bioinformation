#!/usr/bin/perl -w
use strict;

if(@ARGV<1){
	die "perl $0 <expression_file>\n";
}

my $file=shift;
open my $code, ">","correlation-heatmap.R" or die $!;
print $code <<CODE;
library("pheatmap")
data<-read.table("$file",sep = "\t",head=T)
rownames(data)<-data[,1]
len<-length(data)
data<-as.matrix(data[,2:len])
a=(data>0)
data[which(a==TRUE)] <- log(data[which(a==TRUE)])
pdf("CorrelationHeatmap.pdf")
mycolors <- colorRampPalette(c('blue','yellow','red'))(1001)
pheatmap(
	data,
	show_rownames=T,
	show_colnames=T,
	col=mycolors,
	cluster_rows=T,
	cluster_cols=T,
	legend=TRUE,
	fontsize=4,
	main="Heatmap of all samples",
	display_numbers=FALSE,
)
dev.off()
CODE

system("/ifswh1/BC_RD/RD_COM/USER/linruichai/RNA_module/Correlation/Correlation_heatmap_venn/bin/Rscript correlation-heatmap.R");
exit;
