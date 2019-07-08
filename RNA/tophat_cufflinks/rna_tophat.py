import os
import sys,getopt
import subprocess
import random
def main(argv):
    """
    tophat pepline. sample information file should has two column.
    """
    inputfile = ''
    outputfile = ''
    ref = ''
    nc = ''
    qual = ''
    try:
		opts, args = getopt.getopt(argv,"hi:o:r:s:g:t:q:",["ifile=","ofile=","refer=","seq=","gff=","ncpus=","q="])
    except getopt.GetoptError:
        print('python2.7 rna_tophat.py -i <sample information file> -o <directory to store tophat res> -r <reference genome path> -s <reference sequence name> -g <GFF3 or GTF file> -t <number of threads> -q <--phred64-qual or --solexa-qual>')
        sys.exit(2)
    for opt, arg in opts:
        #print(opt)
        #print(arg)
        if opt == '-h':
            print('python2.7 rna_tophat.py -i <sample information file> -o <directory to store tophat res> -r <reference genome path> -s <reference sequence name> -g <GFF3 or GTF file> -t <number of threads> -q <--phred64-qual or --solexa-qual>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputpath = arg
        elif opt in ("-r", "--refer"):
            ref = arg
        elif opt in ("-s", "--seq"):
            seq = arg
        elif opt in ("-g","--gff"):
            gff = arg
        elif opt in ("-t", "--ncpus"):
            nc = arg
        elif opt in ("-q", "--q"):
            qual = arg
	
	print('Sample information file is: %s' %inputfile)
    print('Output path is: %s' %outputpath)
    if not os.path.exists(outputpath):
        os.makedirs(outputpath)
    samples = open(inputfile,'r')
    lines = samples.readlines()
    info_dict = {}
    for l in lines:
        infos = l.strip().split()
        if infos[0] in info_dict.keys():
            info_dict[infos[0]].append(infos[1])
        else:
            info_dict[infos[0]] = [infos[1]]
    for k,v in info_dict.items():
        tophat_log_file = '%s/%s.tophat.log' %(outputpath,k)
        cufflink_log_file = '%s/%s.cufflink.log' %(outputpath,k)
        #subprocess.call("touch %s" %log_file,shell=True)
        rand_n = str(random.random()*1e7)[0:6]
        print('tophat pair: %s + %s' %(v[0],v[1]))
        ##use tophat and bowtie2 anlign to genome.
	subprocess.call("tophat2  --max-intron-length 100000 -m 1 -r 20 %s --mate-std-dev 20 --coverage-search --microexon-search -p %s -o %s/%s_tophat2 -G %s %s %s %s 2>%s" %(qual, nc, outputpath,k, gff, ref, v[0], v[1], tophat_log_file),shell=True)
        ##run cufflinks
        subprocess.call("/home/luhuifang/software/cufflilnks/cufflinks-2.2.1.Linux_x86_64/cufflinks -p %s -o %s/%s_cufflinks %s/%s_tophat2/accepted_hits.bam 2>%s" %(nc, outputpath, k, outputpath, k , cufflink_log_file),shell=True)

    assembline = open('%s/assemblines.txt' %outputpath,'w')
    for root, dirnames, filenames in os.walk(outputpath):
        for filename in filenames:
            if filename == 'transcripts.gtf':
                assembline.write('%s\n' %os.path.join(root, filename))
    assembline.close()

    ##run cuffmerge
    subprocess.call("/home/luhuifang/software/cufflilnks/cufflinks-2.2.1.Linux_x86_64/cuffmerge -s %s -g %s -p %s -o %s/cuffmerge %s/assemblines.txt" %(seq, gff, nc, outputpath, outputpath),shell=True)
    #subprocess.call("cuffmerge -s",shell=True)
    ##
    print('All done!')
    return

if __name__ == '__main__':
    main(sys.argv[1:])
