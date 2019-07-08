import re
import os
import sys
import argparse
import pysam
import logging
import multiprocessing

class ParseStLFRBam(object):
	def __init__(self, inputfile, outdir, distance=5000, readsnum=3, circlegenome=False, insertsize=2000, thread=1, debug=True):
		self.check_path(inputfile, True)
		self.check_path(outdir)
		self.inputfile = inputfile
		self.outdir = outdir
		self.distance = distance
		self.readsnum = readsnum
		self.circlegenome = circlegenome
		self.insertsize = insertsize
		self.thread = thread
		level = logging.DEBUG if debug else logging.INFO
		self.logf = os.path.join(outdir, '%s.log' % os.path.basename(inputfile))
		format = ('%(asctime)s — %(name)s — %(levelname)s — %(funcName)s: %(lineno)d — %(message)s')
		logging.basicConfig(level=level, format=format, filename=self.logf, filemode='a')
	

	@staticmethod
	def check_path(path, isFile=False):
		if isFile:
			if not os.path.isfile(path):
				raise ValueError("Path {0} is not a file!".format(path))
			if not os.path.exists(path):
				raise IOError("File {0} is not found!".format(path))
		else:
			if not os.path.exists(path):
				os.makedirs(path)
			if not os.path.isdir(path):
				raise ValueError("Path {0} is not a directory!".format(path))
		return True
	
	def readFile(self):
		logging.info('Start read input file!')
		bamfile = pysam.AlignmentFile(self.inputfile)
		try:
			bamfile.check_index()
		except ValueError:
			raise IOError('Read index error, please create index for {0}'.format(self.inputfile))
		logging.info('Done read input file!')
		return bamfile
	
	def readHeader(self, samfile):
		header = {}
		logging.info('Start read sam header!')
		for ele in samfile.header['SQ']:
			header[ele['SN']] = ele['LN']
		logging.info('Done read sam header!')
		return header
	
	def parseSamFile(self, samfile, header):
		logging.info('Start parse samfile!')
		#pool = multiprocessing.Pool(processes = self.thread)
		for chr in header:
			chr_len = header[chr]
			chr_reads = samfile.fetch(chr)
			out_preffix = os.path.join(self.outdir, '{0}'.format(chr))
			self.parseOneChr(chr,chr_reads, out_preffix, chr_len)
			#pool.apply_async(self.parseOneChr, (chr,chr_reads, out_preffix, chr_len, ))
		#pool.close()
		#pool.join() 
		logging.info('Done parse samfile!')
		samfile.close()

	def parseOneChr(self, chr, chr_reads, out_preffix, chr_len):
		logging.info('Start parse {0} reads'.format(chr))
		barcode_region = {}
		barcode_reads_num = []
		barcode_fragment_num = []
		for read in chr_reads:
			if not read.is_paired:
				continue
			#if read.is_read2:
			if read.template_length <= 0:
				continue
			if read.is_unmapped or read.mate_is_unmapped:
				continue
			if read.reference_name != read.next_reference_name:
				continue
			barcode = re.search( r'.*/(\d+_\d+_\d+)', read.query_name).group(1)
			start, end = self.get_start_end_position(read, chr_len)
			if start is None:
				continue
			tmp = [start, end]
			self._append_array_to_dict(barcode_region, barcode, tmp)
		
		#stat
		for barcode in barcode_region:
			tmp_reads_num = '{0}\t{1}\n'.format(barcode, len(barcode_region[barcode]))
			barcode_reads_num.append(tmp_reads_num)
			if len(barcode_region[barcode]) > self.readsnum:
				regionArraySort = sorted(barcode_region[barcode], key=lambda x:x[0])
				barcode_frag_num_str = self.parseBarcodeSplitFrag(barcode, regionArraySort, chr_len)
				barcode_fragment_num.append(barcode_frag_num_str)
			
			#write results
			if len(barcode_reads_num) >= 10000:
				self.writeResult('{0}.readnum.stat'.format(out_preffix), barcode_reads_num)
				barcode_reads_num = []

			if len(barcode_fragment_num) >= 5000:
				self.writeResult('{0}.fragnum.stat'.format(out_preffix), barcode_fragment_num)
				barcode_fragment_num = []

		self.writeResult('{0}.readnum.stat'.format(out_preffix), barcode_reads_num)
		self.writeResult('{0}.fragnum.stat'.format(out_preffix), barcode_fragment_num)
		logging.info('Done parse {0} reads'.format(chr))

	def writeResult(self, outf, writeArray):
		if len(writeArray) > 0:
			with open(outf, 'a') as f:
				for w in writeArray:
					#writer = w + '\n'
					f.write(w)
			logging.info('Done write {0} records to {1}.'.format(len(writeArray), outf))

	def get_start_end_position(self, read, chr_len):
		temp_len = read.template_length
		pos = read.reference_start
		pos_end = read.reference_end
		mpos = read.next_reference_start
		mpos_end = pos + temp_len

		start = pos if pos < mpos else mpos
		end = start + temp_len
		#if end - start + 1  > self.insertsize:
		if temp_len  > self.insertsize:
			if self.circlegenome:
				#if chr_len - end + 1 + start > self.insertsize:
				if chr_len - mpos + 1 + pos_end > self.insertsize:
					return None, None
				else:
					#s = end - chr_len
					#end = start
					#start = s
					start = mpos - chr_len
					end = pos_end
			else:
				return None, None
		return start, end

	@staticmethod
	def _append_array_to_dict(dicts, key, arrayValue):
		if key in dicts.keys():
			dicts[key].append(arrayValue)
		else:
			dicts[key] = [arrayValue]

	def parseBarcodeSplitFrag(self, barcode, regionArray, chr_len):
		barcode_frag = {}
		frag_id = 0
		start = None
		end = None
		rnum = 0
		for region in regionArray:
			if start is None:
				start = region[0]
				end = region[1]
			else:
				if region[0] - end + 1 >= self.distance:
					barcode_frag[frag_id] = [start, end, rnum]
					frag_id += 1
					start = region[0]
					rnum = 0
				end = region[1] if region[1] > end else end
			rnum += 1
		barcode_frag[frag_id] = [start, end, rnum]

		#merge first and last frag if circlegenome and less than distance
		if self.circlegenome:
			if chr_len - barcode_frag[frag_id][1] + barcode_frag[0][0] < self.distance:
				barcode_frag[0][0] = barcode_frag[frag_id][1] - chr_len
				barcode_frag[0][2] = barcode_frag[frag_id][2] + barcode_frag[0][2]
				del barcode_frag[frag_id]

		barcode_frag_num = ''
		for fid in barcode_frag:
			length = barcode_frag[fid][1] - barcode_frag[fid][0] + 1
			barcode_frag_num = barcode_frag_num + '{0}\tf{1}\t{2}\t{3}\t{4}\t{5}\n'.format(barcode, fid, barcode_frag[fid][2], length, barcode_frag[fid][0], barcode_frag[fid][1])


		return barcode_frag_num

	def run(self):
		samfile = self.readFile()
		header = self.readHeader(samfile)
		self.parseSamFile(samfile, header)


if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('-i', '--input', help='Input file, sam or bam format.Required', required=True)
	parser.add_argument('-o', '--outdir', help='Output directory for statistical results.Required', required=True)
	parser.add_argument('-d', '--distance', help='Distance for split fragments.(Default=5000)', default=5000, type=int)
	parser.add_argument('-n', '--readsnum', help='Number of PE reads for split fragments.(Default=3)', default=3, type=int)
	parser.add_argument('-c', '--circlegenome', help='Genome is circle.(Default=False)', default=False, type=bool)
	parser.add_argument('-s', '--insertsize', help='Maximum insert size for PE reads.(Default=2000) ', default=2000, type=int)
	parser.add_argument('-t', '--thread', help='Number of thread.(Default=1)', default=1, type=int)

	args = parser.parse_args()
	parseBam = ParseStLFRBam(args.input, args.outdir, args.distance, args.readsnum, args.circlegenome, args.insertsize, args.thread)
	parseBam.run()
