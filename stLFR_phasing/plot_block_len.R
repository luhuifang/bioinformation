args=commandArgs(T)
a_barcode=args[1]
a_normal=args[2]
befor=args[3]
outfile=args[4]

library(ggplot2)
after_bar <- read.table(a_barcode, header = F, sep = "\t")
after_nor <- read.table(a_normal, header = F, sep = "\t")
before <- read.table(befor, header = F, sep = "\t")

after_bar$label <- "after_barcode_extends"
after_nor$label <- "after_normal_extends"
before$label <- "before_extends"

res <- rbind(after_bar,after_nor,before)

png(outfile,width=600,height=800)

ggplot(res, aes(x = V5, fill = label)) + xlab("block_length") + geom_density(alpha = 0.3)

dev.off()
