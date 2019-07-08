args=commandArgs(T)
in1=args[1]
outdir=args[2]
column1=args[3]
column2=args[4]
xlab=args[5]
ylab=args[6]
prefix=args[7]
minx=args[8]
maxx=args[9]
miny=args[10]
maxy=args[11]

library(ggplot2)
stat_file_path = in1
assemblystat <- read.table(stat_file_path, header = FALSE)
x <- assemblystat[, as.numeric(column1)]
y <- assemblystat[, as.numeric(column2)]
#kmer_extend_coverage <- assemblystat$kmer_extend_coverage
#OLC_coverage <- assemblystat$OLC_coverage
#kmer_extend_len <- assemblystat$kmer_extend_len
#OLC_len <- assemblystat$OLC_len


figure_path <- file.path(outdir, paste(prefix, ".png", sep=""))
png(figure_path, width=861, height=548)
ggplot(assemblystat, aes(x = x, y = y)) + 
  geom_point(alpha=0.1) +
  xlab(xlab) +
  ylab(ylab) +
  xlim(as.numeric(minx), as.numeric(maxx)) +
  ylim(as.numeric(miny), as.numeric(maxy)) +
  #stat_density2d(aes(alpha = ..density..), geom = "raster", contour = FALSE) +
  stat_smooth(method = "lm") +
  geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed", size = 1)
dev.off()

#figure_path <- "E:\\BGI_work\\testing\\stLFR\\assembly_test\\Kmer_OLC_coverage_len.png"
#png(figure_path, width=861, height=548)
#ggplot(assemblystat, aes(x = kmer_extend_len, y = OLC_len)) + 
#  geom_point(alpha=0.1) +
#  xlab("kmer_extend_len  (bp)") +
#  ylab("OLC_len (bp)") +
  #xlim(0,3000) +
  #ylim(0,3000) +
  #stat_density2d(aes(alpha = ..density..), geom = "raster", contour = FALSE) +
  #stat_smooth(method = "lm") +
  #geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed", size = 1)
#dev.off()
