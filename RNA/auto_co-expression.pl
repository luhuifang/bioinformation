#!/usr/bin/perl -w
use strict;

=head1 Description

 This program is based on WGCNA package of R, it can automatic construction of co-expression networks, 
 and you can set some parameters include: input file's format, TOMType, minModuleSize and so on.

=head1 Author

 LuHuifang  luhuifang@genomics.cn
 Create date: 2016-1-22

=head1 Usage

 perl auto_co-expression.pl -input <inputfile> [-options] 

=head1 Options

 -input		the file of expression data 
 -format	csv: input file is CSV file; table: input file is a table [default: table]
 -exprCol	you can set -exprCol to tell program which columns are expression data,
 		for example 2:30 represent column 2 to column 30 is expression data.[default all columns are expression data]
 -probes	the file that contain some genes that you interested in, 
		the number of genes usually more than 20.
		Note that if set -probes parameters, this program will only anaysis these genes.
 -workDir	your working directory, please set a absolute path, or it will not working. [default: current directory]
 -prefix	all new graph will named with prefix [default: Samples]
 -TOMType	TOM type, "unsigned" or "signed" [default: unsigned]
 -minModuleSize	minimum module size to be used in module detection procedure [default: 30]
 -maxBlockSize	integer giving maximum block size for module detection. 
		Ignored if blocks above is non-NULL. 
		Otherwise, if the number of genes in datExpr exceeds maxBlockSize, 
		genes will be pre-clustered into blocks whose size should not exceed maxBlockSize.
		[default: 5000]
 -mergeCutHeight dendrogram cut height for module merging [default: 0.15]
 -nSelect	the number of genes in networks visualization within R [default: all genes]
 -outFormat	export network file's format, "VisANT" or "Cytoscape" [default: Cytoscape]
 -nTop		the number of genes when export network [default: all genes]
 -threshold	the threshold of connectivity when export network [default: 0]
 -q		bind job to queue(s)
 -P		project_name,set job's project
 -vf		request the given resources, [deflat=1G]
		if there are less than 5000 genes, you can set vf=2G or much less.
		if there are 5000-20000 genes, you will set vf=5G-10G or more.
		if there are more than 20000 genes, you'd better set vf=15G or more than it.

=head1 Examples

 perl auto_co-expression.pl -input test.fpkm.xls -format table -q st.q -P F15ZQSQS2015 -vf 0.5G
 perl auto_co-expression.pl -input test.csv -format csv -exprCol 9:142 -q st.q -P F15ZQSQS2015 -vf 0.5G -outFormat VisANT -prefix test

=cut
use Getopt::Long;
my($format,$exprCol,$input,$probes,$workDir,$prefix);
my($TOMType,$minModuleSize,$maxBlockSize,$mergeCutHeight,$nSelect,$outFormat,$nTop,$threshold,$help);
my($q,$P,$vf);
GetOptions(
	"format:s"=>\$format,
	"exprCol:s"=>\$exprCol,
	"input:s"=>\$input,
	"probes:s"=>\$probes,
	"workDir:s"=>\$workDir,
	"prefix:s"=>\$prefix,
	"TOMType:s"=>\$TOMType,
	"minModuleSize:i"=>\$minModuleSize,
	"maxBlockSize:i"=>\$maxBlockSize,
	"mergeCutHeight:f"=>\$mergeCutHeight,
	"nSelect:i"=>\$nSelect,
	"outFormat:s"=>\$outFormat,
	"nTop:i"=>\$nTop,
	"threshold:f"=>\$threshold,
	"q:s"=>\$q,
	"P:s"=>\$P,
	"vf:s"=>\$vf,
	"help|?"=>\$help,
);
die `pod2text $0` unless($input);

my $currentDir=`pwd`;
chomp($currentDir);
$workDir ||= "$currentDir";
$prefix ||= "Samples";
$format ||= "table";
$TOMType ||= "unsigned";
$minModuleSize ||= 30;
$maxBlockSize ||= 5000;
$mergeCutHeight ||= 0.15;
$outFormat ||= "Cytoscape";
$threshold ||= 0;
$vf ||= "1G";

mkdir("$workDir/Data") unless(-d "$workDir/Data");
mkdir("$workDir/Shell") unless(-d "$workDir/Shell");
mkdir("$workDir/Plots") unless(-d "$workDir/Plots");
mkdir("$workDir/Network") unless(-d "$workDir/Network");

my %probes=();
if($probes){
	open PROBES,"<$probes" or die $!;
	while(<PROBES>){
		chomp;
		$probes{$_}=$_;
	}
}
close PROBES;

open SHELL,">$workDir/Shell/$prefix.co-expression.R" or die $!;
my $DataPre=<<"DATA";
##################### Set workdir, Library packages, Read data file #############
workDir="$workDir";
setwd(workDir);
library(WGCNA);
library(iterators);
options(stringsAsFactors = FALSE);
enableWGCNAThreads();
DATA
print SHELL "$DataPre\n";

if($format eq "table" ){
	open OUT,">$workDir/Data/input.xls" or die $!;
	open TABLE,"<$input" or die $!;
	my $header=<TABLE>;
	print OUT "$header";
	while(<TABLE>){
		chomp;
		my ($gene,$expr)=(split /\s+/,$_,2)[0,1];
		if($probes){
			if(exists $probes{$gene} && $expr=~/[^0\s]/){
				print OUT "$gene\t$expr\n";
			}
		}elsif(!$probes){
			if($expr=~/[^0\s]/){
				print OUT "$gene\t$expr\n";
			}
		}
	}
	close TABLE;
	close OUT;
	print SHELL "data = read.table(file = \"$workDir/Data/input.xls\",header = TRUE,row.names = 1);\ndatExpr0 = as.data.frame(t(data));\n";
}elsif($format eq "csv" && !$exprCol){
	open OUT,">$workDir/Data/input.csv" or die $!;
	open CSV,"<$input" or die $!;
	my $header=<CSV>;
	print OUT "$header";
	while(<CSV>){
		chomp;
		my ($gene,$expr)=(split /,/,$_,2)[0,1];
		if($probes){
			if(exists $probes{$gene} && $expr=~/[^0\s",]/){
				print OUT "$gene,$expr\n";
			}
		}elsif(!$probes){
			if($expr=~/[^0\s",]/){
				print OUT "$gene,$expr\n";
			}
		}
	}
	close CSV;
	close OUT;
	print SHELL "data = read.csv(file = \"$workDir/Data/input.csv\",header = T);\ndatExpr0 = as.data.frame(t(data[,-1]));\nnames(datExpr0) = data[,1];\n";
}elsif($format eq "csv" && $exprCol){
	open OUT,">$workDir/Data/input.csv" or die $!;
	open CSV,"<$input" or die $!;
	my ($start,$end) = (split /:/,$exprCol)[0,1];
	my $header=<CSV>;
	chomp $header;
	my @header=split(/,/,$header);
	my $g=$header[0];
	my $e=join(",",$header[$start-1 .. $end-1]);
	print OUT "$g,$e\n";
	while(<CSV>){
		chomp;
		my @csvline=split(/,/,$_);
		my $gene=$csvline[0];
		my $expr=join(",",$csvline[$start-1 .. $end-1]);
		if($probes){
			if(exists $probes{$gene} && $expr=~/[^0\s",]/){
				print OUT "$gene,$expr\n";
			}
		}elsif(!$probes){
			if($expr=~/[^0\s",]/){
				print OUT "$gene,$expr\n";
			}
		}
	}
	close CSV;
	close OUT;
	print SHELL "data = read.csv(file = \"$workDir/Data/input.csv\",header = T);\ndatExpr0 = as.data.frame(t(data[,-1]));\nnames(datExpr0) = data[,1];\n";
}

my $goodsamples=<<"goodsamples";
##################### Filter bad genes and samples ###################
gsg = goodSamplesGenes(datExpr0,verbose = 3);
if (!gsg\$allOK){
	if (sum(!gsg\$goodGenes)>0) printFlush(paste("Removing genes:",paste(names(datExpr0)[!gsg\$goodGenes], collapse = ", ")));
	if (sum(!gsg\$goodSamples)>0) printFlush(paste("Removing samples:",paste(rownames(datExpr0)[!gsg\$goodSamples], collapse = ", ")));
	datExpr0 = datExpr0[gsg\$goodSamples,gsg\$goodGenes];
}
goodsamples
print SHELL "$goodsamples\n";

my $samplesClust=<<"samplesClust";
##################### Samples clust and Visualization ###################
sampleTree = hclust(dist(datExpr0),method = "average");
treeHeights = sort(sampleTree\$height);
cutHeight = treeHeights[length(treeHeights)]*0.85;

pdf(file = "$workDir/Plots/$prefix-sampleClustering.pdf",width = 12,height = 9);
par(cex = 0.8);
par(mar = c(0,4,2,0));
plot(
        sampleTree,
        main = "Sample clustering to detect outliers",
        sub = "",
        xlab = "",
        cex.lab = 1.5,
        cex.axis = 1.5,
        cex.main = 2
);
abline(h = cutHeight,col = "red");

##################### Remove outliers ##############################
clust = cutreeStatic(sampleTree,cutHeight = cutHeight, minSize = 2);
table(clust);
keepSamples = (clust>0);
datExpr = datExpr0[keepSamples,];
a = apply(datExpr,2,function(x) all(x==0));
allFALSE = all(a==FALSE);
if(!allFALSE) datExpr = datExpr[-which(a==TRUE)];
nGenes = ncol(datExpr);
nSamples = nrow(datExpr);
dev.off();
save(datExpr,file="$workDir/Data/$prefix-01-dataInput.RData");

##################### Calculate power and Visualization ####################
powers = c(c(1:10),seq(12,30,2));
sft = pickSoftThreshold(datExpr,powerVector = powers, verbose = 5);
signs = -sign(sft\$fitIndices[,3])*sft\$fitIndices[,2];
sortSigns = sort(signs);
maxSign = sortSigns[length(sortSigns)];
if(maxSign>0.9){
	h = 0.9;
}else{
	h = sortSigns[length(sortSigns)]*0.99;
}
n=0;
for (i in signs){
	n = n+1;
	power = sft\$fitIndices[,1][n];
	if(i >= h) break
}

pdf(file="$workDir/Plots/Soft_Threshold.pdf",width=9,height=5);
par(mfrow = c(1,2));
cex1 = 0.9;
plot(
	sft\$fitIndices[,1],
	signs,
	xlab="Soft Threshold (power)",
	ylab="Scale Free Topology Model Fit,signed R^2",
	type="n",
	main = paste("Scale independence")
);
text(
	sft\$fitIndices[,1],
        signs,
        labels=powers,
        cex=cex1,col="red"
);

abline(h=h,col="red");
plot(
        sft\$fitIndices[,1],
        sft\$fitIndices[,5],
        xlab="Soft Threshold (power)",
        ylab="Mean Connectivity",
        type="n",
        main = paste("Mean connectivity")
);
text(
        sft\$fitIndices[,1],
        sft\$fitIndices[,5],
        labels=powers,
        cex=cex1,col="red"
);
dev.off();

####################### One-step network construction and module detection #########################
net = blockwiseModules(
	datExpr,
	power = power,
	TOMType = "$TOMType",
	minModuleSize = $minModuleSize,
	maxBlockSize = $maxBlockSize,
	reassignThreshold = 0,
	mergeCutHeight = $mergeCutHeight,
	numericLabels = TRUE,
        pamRespectsDendro = FALSE,
        saveTOMs = TRUE,
        saveTOMFileBase = "$workDir/Data/$prefix",
        verbose = 3
);

##################### Visualization #####################
pdf(file="$workDir/Plots/$prefix-dendrogram.pdf",width=12,height=9);
mergedColors = labels2colors(net\$colors);
plotDendroAndColors(
        net\$dendrograms[[1]],
        mergedColors[net\$blockGenes[[1]]],
        "Module colors",
        dendroLabels = FALSE,
        hang = 0.03,
        addGuide = TRUE,
        guideHang = 0.05,
);
dev.off();

############################ Save network ##################################
moduleLabels = net\$colors;
moduleColors = labels2colors(net\$colors);
MEs = net\$MEs;
geneTree = net\$dendrograms[[1]];
save(MEs, moduleLabels, moduleColors, geneTree,file = "$workDir/Data/$prefix-02-networkConstruction-auto.RData");

############################### Visualization of networks within R #############
TOM=TOMsimilarityFromExpr(datExpr,power=power);
dissTOM = 1-TOM;
samplesClust
print SHELL "$samplesClust\n";

if($nSelect){
	my $visualization=<<"visualization";
nSelect = $nSelect;
set.seed(10);
select = sample(nGenes, size = nSelect);
selectTOM = dissTOM[select, select];
selectTree = hclust(as.dist(selectTOM), method = "average");
selectColors = moduleColors[select];
plotDiss = selectTOM^7;
pdf(file="$workDir/Plots/dissTOM_heatmap_select.pdf",width=9,height=9);
visualization
	print SHELL "$visualization\n";
}else{
	my $Visualization=<<"Visualization";
plotDiss = dissTOM^7;
pdf(file = "$workDir/Plots/disstom_heatmap.pdf",width=9,height=9);
selectTree = geneTree;
selectColors = moduleColors;
Visualization
	print SHELL "$Visualization\n";
}

my $plot=<<"plot";
diag(plotDiss) = NA;
TOMplot(plotDiss, selectTree, selectColors, main = "Network heatmap plot, selected genes");
dev.off();

############################# Export TOM #####################################
MC = table(moduleColors);
for (color in names(MC)){
        module = color;
	if (MC[module] >1){
        probes = names(datExpr);
        inModule = (moduleColors==module);
        modProbes = probes[inModule];
	modTOM = TOM[inModule, inModule];
        dimnames(modTOM) = list(modProbes,modProbes);
plot
print SHELL "$plot\n";

if($nTop){
	my $top=<<"top";
        nTop = $nTop;
	IMConn = softConnectivity(datExpr[,modProbes]);
	top = (rank(-IMConn) <= nTop);
	modTOM = modTOM[top,top],
top
	print SHELL "$top\n";
}

if($outFormat eq "VisANT"){
	mkdir("$workDir/Network/01.VisANT") unless(-d "$workDir/Network/01.VisANT");
	my $visant=<<"visant";
	vis = exportNetworkToVisANT(
		modTOM,
		file = paste("$workDir/Network/01.VisANT/VisANTInput-",module,".txt",sep=""),
		weighted = TRUE,
		threshold = $threshold,
	);
}}

allModule = is.finite(match(moduleColors, names(MC)));
allProbes = probes[allModule];
allTOM = TOM[allModule, allModule];
dimnames(allTOM) = list(allProbes,allProbes);
vis = exportNetworkToVisANT(
	allTOM,
	file = paste("$workDir/Network/01.VisANT/VisANTInput-all.txt",sep=""),
	weighted = TRUE,
	threshold = $threshold,
);
visant
	print SHELL "$visant\n";
}elsif($outFormat eq "Cytoscape"){
	mkdir("$workDir/Network/02.Cytoscape") unless(-d "$workDir/Network/02.Cytoscape");
	my $cytoscape=<<"cytoscape";
	cyt = exportNetworkToCytoscape(
		modTOM,
		edgeFile = paste("$workDir/Network/02.Cytoscape/CytoscapeInput-edges-", module, ".txt", sep=""),
		nodeFile = paste("$workDir/Network/02.Cytoscape/CytoscapeInput-nodes-", module, ".txt", sep=""),
		weighted = TRUE,
		threshold = $threshold,
	);
}}

allModule = is.finite(match(moduleColors, names(MC)));
allProbes = probes[allModule];
allTOM = TOM[allModule, allModule];
dimnames(allTOM) = list(allProbes,allProbes);
cyt = exportNetworkToCytoscape(
	allTOM,
	edgeFile = paste("$workDir/Network/02.Cytoscape/CytoscapeInput-edges-all.txt", sep=""),
	nodeFile = paste("$workDir/Network/02.Cytoscape/CytoscapeInput-nodes-all.txt", sep=""),
	weighted = TRUE,
	threshold = $threshold,
);
cytoscape
	print SHELL "$cytoscape\n";
}
close SHELL;

open SH,">$workDir/run_co-expression.sh" or die $!;
print SH "/ifs4/BC_PUB/biosoft/pipeline/Package/R-3.1.1/bin/Rscript $workDir/Shell/$prefix.co-expression.R ";
close SH;

#`qsub -cwd -q $q -P $P -l vf=$vf $workDir/run_co-expression.sh`;

