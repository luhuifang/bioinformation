#!/usr/bin/python3

import os
import sys
import json
import argparse

def read_barcode_list(blocklist):
	'''
	result format
	key: chr
	value: {block_id: {chr: chr1, block_start: 123, block_end: 5478, 
						pos_list: [], hap1list: [], hap2list:[]
						barcode1list: [], barcode2list: []}
			}
	'''
	block_barcode = {}
	with open(blocklist, 'r') as block:
		for l in block:
			lines_info = l.strip().split('\t')
			chr_id = lines_info[0]
			block_index = eval(lines_info[1])
			pos = eval(lines_info[2])
			hap1 = lines_info[3]
			hap2 = lines_info[4]
			

			if lines_info[5] == 'None': ## barcodes1 is none
				barcodes1 = []
			else:
				barcodes1 = lines_info[5].split(',')

			if lines_info[6] == 'None': ## barcodes2 is none
				barcodes2 = []
			else:
				barcodes2 = lines_info[6].split(',')
			
			if not chr_id in block_barcode:  ## first add
				block_barcode[chr_id] = {}
				tmp = {'chr': chr_id, 
						'block_index': block_index,
						'block_start': pos, 
						'block_end': pos,
						'pos_list': [pos],
						'hap1list': [hap1],
						'hap2list': [hap2],
						'barcode1list': barcodes1,
						'barcode2list': barcodes2,
					}
				block_barcode[chr_id][block_index] = tmp
			else: ## add dict
				if block_index in block_barcode[chr_id]: 
					tmp = block_barcode[chr_id][block_index]
					tmp['block_end'] = max(tmp['block_end'], pos)
					tmp['pos_list'].append(pos)
					tmp['hap1list'] += hap1
					tmp['hap2list'] += hap2
					tmp['barcode1list'] = list(set(tmp['barcode1list'] + barcodes1))
					tmp['barcode2list'] = list(set(tmp['barcode2list'] + barcodes2))
					block_barcode[chr_id][block_index] = tmp
				else:
					tmp = {'chr': chr_id, 
						'block_index': block_index,
						'block_start': pos, 
						'block_end': pos,
						'pos_list': [pos],
						'hap1list': [hap1],
						'hap2list': [hap2],
						'barcode1list': barcodes1,
						'barcode2list': barcodes2,
					}
					block_barcode[chr_id][block_index] = tmp

	return block_barcode

def get_pos_block_index(block_barcodes):
	'''
	key: chr
	value: {pos: index, pos: index, ... }
	'''
	pos_bindex = {}
	for ch in block_barcodes: ## chr
		for b in block_barcodes[ch]: ## barcode index
			for pos in block_barcodes[ch][b]['pos_list']:
				if ch in pos_bindex:
					pos_bindex[ch][pos] = block_barcodes[ch][b]['block_index']
				else:
					pos_bindex[ch] = {}
					pos_bindex[ch][pos] = block_barcodes[ch][b]['block_index']
	return pos_bindex

def extends_with_barcodes(block_barcodes):
	blocks_extends_with_barcodes = {}
	for ch in block_barcodes:
		blocks_extends_with_barcodes_chr = extends_with_barcodes_per_chr(block_barcodes[ch])

		blocks_extends_with_barcodes[ch] = blocks_extends_with_barcodes_chr
	return blocks_extends_with_barcodes

def extends_with_barcodes_per_chr(block_barcodes):
	blocks_extends_with_barcodes = {}
	'''
	input format: 
		key: block_indexs
		vlaue: {block info}
	'''
	count = 0
	barcode_indexs = sorted(block_barcodes.keys()) # block_index

	this_block = block_barcodes[barcode_indexs[0]]
	for index in range(len(barcode_indexs)):
		if index == 0:
			continue
		next_block = block_barcodes[barcode_indexs[index]]
		
		can_merge, new_block = merge_blocks(this_block, next_block)

		if not can_merge: ## can not merge this_block and next_block
			this_block['block_index'] = count
			blocks_extends_with_barcodes[count] = this_block
			count += 1
			this_block = next_block
		else:
			print('Merge with barcodes: next_index is {0}'.format(index))
			this_block = new_block
	this_block['block_index'] = count
	blocks_extends_with_barcodes[count] = this_block
	
	return blocks_extends_with_barcodes

def merge_blocks(block1, block2):
	can_merge, major_idx, minor_idx = get_merge_index(block1, block2)
	if not can_merge:
		return can_merge, None
	else:
		return can_merge, merge(block1, block2, major_idx, minor_idx)


def merge(block1, block2, major_idx, minor_idx):
	new_block = block1
	new_block['block_end'] = block2['block_end'] ## update block_end
	new_block['pos_list'] += block2['pos_list'] ## append block2's position into block1
	extends_haplist_barlist(new_block, block2, major_idx)
	extends_haplist_barlist(new_block, block2, minor_idx)
	return new_block

def extends_haplist_barlist(block1, block2, idx_array):
	hap = 'hap{0}list'.format(idx_array[0])
	hap_extend = 'hap{0}list'.format(idx_array[1])
	block1[hap] += block2[hap_extend]
	
	bar = 'barcode{0}list'.format(idx_array[0])
	bar_extend = 'barcode{0}list'.format(idx_array[1])
	block1[bar] += block2[bar_extend]

def get_merge_index(block1, block2):
	
	barlists = []
	barlists.append(block1['barcode1list'])
	barlists.append(block1['barcode2list'])
	barlists.append(block2['barcode1list'])
	barlists.append(block2['barcode2list'])
	
	merge_flag = False
	max_len = -1
	for i in [0,1]:
		for j in [2,3]:
			shares, lens = has_share_barcode(barlists[i], barlists[j])
			if shares and lens > max_len:
				merge_flag = True
				max_len = lens
				major_idx = [i+1,j-1]
				minor_idx = [rev_hap_index(i), rev_hap_index(j)]
	if merge_flag:
		if max_len >= 2:
			return merge_flag, major_idx, minor_idx
		else:
			return False, None, None
	else:
		return merge_flag, None, None

def rev_hap_index(idx):
	rev_index = {0:2, 1:1, 2:2, 3:1}
	return rev_index[idx]

def has_share_barcode(barlist1, barlist2):
	share = list(set(barlist1) & set(barlist2)) ## share barcode
	share_len = len(share)
	if share_len > 0:
		return True, share_len
	else:
		return False, share_len


def run_extends_with_barcodes(blocklist, outfile):
	block_barcodes = read_barcode_list(blocklist) ## read file
	
	## write out stat before extends
	outf = '{0}.before.extends.stat'.format(outfile)
	write_blocks_stat(outf, block_barcodes)
	## end write

	extend_block = extends_with_barcodes(block_barcodes) ## extends_with_barcodes
	pos_bindex = get_pos_block_index(extend_block)
	return extend_block, pos_bindex

def run_extends_with_normal_block(normallist, extend_block, tumor_pos_bindex):

	normal_block_barcodes = read_barcode_list(normallist) ## read normal file
	normal_pos_bindex = get_pos_block_index(normal_block_barcodes)  ## normal_pos_bindex

	blocks_extends_with_normal = extends_with_normal_block(normal_block_barcodes, normal_pos_bindex, extend_block, tumor_pos_bindex) ## extend with normal
	return blocks_extends_with_normal


def extends_with_normal_block(normal_block_barcodes, normal_pos_bindex, extend_block, tumor_pos_bindex):
	extends_with_normal_blocks = {}
	for ch in extend_block: ## echo tumor chr
		'''
		input format:
			key: pos
			value: block_index 
		'''
		n_pos_chr = normal_pos_bindex[ch]
		t_pos_chr = tumor_pos_bindex[ch]
		share_block_index = get_share_blockindex(n_pos_chr, t_pos_chr)

		tumor_block = extend_block[ch]
		normal_block = normal_block_barcodes[ch]

		blocks_extends_with_normal = extends_with_normal_block_per_chr(share_block_index, normal_block, tumor_block)

		extends_with_normal_blocks[ch] = blocks_extends_with_normal	
	return extends_with_normal_blocks

def extends_with_normal_block_per_chr(share_block_index, normal_block, tumor_block):
	blocks_extends_with_normal_block = {}
	'''
	input format: 
		key: tumor_index
		value: {{normal_index: num_pos}, ...}
	'''
	#sort_t_index = sorted(share_block_index.keys())
		
	#print('Sorted tumor block: {0}'.format(sort_t_index))
	this_block_index = 0 ## init 
	this_tumor_block = tumor_block[this_block_index]
	
	count = 0
	for idx in range(len(tumor_block.keys())): ## each tumor block index
		print('index: {0}'.format(idx))
		if idx == 0:
			continue

		next_block_index = idx
		next_tumor_block = tumor_block[next_block_index]

		if not this_block_index in share_block_index or not next_block_index in share_block_index: ## not overlap with normal
			print('Not in share_block_index: {0} {1}'.format(this_block_index, next_block_index))
			this_tumor_block['block_index'] = count
			blocks_extends_with_normal_block[count] = this_tumor_block
			count += 1

			#update
			this_block_index = next_block_index
			this_tumor_block = next_tumor_block
			continue

		this_normal_indexs = share_block_index[this_block_index].keys()
		next_normal_indexs = share_block_index[next_block_index].keys()
		share_normal = list(set(this_normal_indexs) & set(next_normal_indexs)) 
		## this_tumor has shared normal inedx with next_tumor

		if len(share_normal) < 1: ## no shared normal block
			print('Not shared normal block: {0} {1}'.format(this_block_index, next_block_index))
			this_tumor_block['block_index'] = count
			blocks_extends_with_normal_block[count] = this_tumor_block
			count += 1

			#update
			this_block_index = next_block_index
			this_tumor_block = next_tumor_block
			continue

		merge_flag = False
		for n_index in share_normal:  ##each normal block
			print('shared normal block_index : {0}'.format(n_index))
			if len(share_block_index[this_block_index][n_index]) < 2 or len(share_block_index[next_block_index][n_index]) < 2: ## shared pos less than 2
				continue
			current_normal_block = normal_block[n_index]

			this_share_pos = share_block_index[this_block_index][n_index]
			next_share_pos = share_block_index[next_block_index][n_index]

			## foreach shared pos 
			can_merge, major_index, minor_index = get_normal_tumor_relation(this_tumor_block, next_tumor_block, current_normal_block, this_share_pos, next_share_pos)
			if not can_merge:
				print('Can not merge')
				continue  ## next shared normal block
			else:
				print('Merge with normal_block: {0} {1}'.format(this_block_index, next_block_index))
				new_block = merge(this_tumor_block, next_tumor_block, major_index, minor_index)
				merge_flag = True
				break

		if not merge_flag: ## not merge
			print('{0} and {1} can not merge, write this_tumor_block'.format(this_block_index, next_block_index))
			this_tumor_block['block_index'] = count
			blocks_extends_with_normal_block[count] = this_tumor_block
			count += 1

			this_block_index = next_block_index
			this_tumor_block = next_tumor_block

		else: ## merge
			print('After merge with normal_block, new_block: {0}'.format(new_block))
			this_block_index = next_block_index ## update this_block_index to next_block_index
			this_tumor_block = new_block ## update this_tumor_block to merged block
	
	this_tumor_block['block_index'] = count
	blocks_extends_with_normal_block[count] = this_tumor_block

	return blocks_extends_with_normal_block

def get_normal_tumor_relation(this_tumor_block, next_tumor_block, normal_block, 
								this_share_pos, next_share_pos):
	'''
	out format:
	return n_h1 -> [this_hap_id, next_hap_id], n_h2 -> [this_hap_id, next_hap_id]
	'''
	n_h1_relation = []
	n_h2_relation = []
	
	#deal with this_tumor and normal
	this_has_relation, this_n_h1, this_n_h2 = normal_tumor_relation(this_share_pos, normal_block, this_tumor_block)
	if not this_has_relation:
		return False, None, None
	
	#deal with next_tumor and normal
	next_has_relation, next_n_h1, next_n_h2 = normal_tumor_relation(next_share_pos, normal_block, next_tumor_block)
	if not next_has_relation:
		return False, None, None
	
	return True, [this_n_h1, next_n_h1], [this_n_h2, next_n_h2] 

def normal_tumor_relation(share_pos, normal_block, tumor_block):
	'''
	output: True/False, normal_h1 -> tumor_hap_id, normal_h2 -> tumor_hap_id
	'''
	n_h1_this = None
	n_h2_this = None
	num_pos = 0
	for pos in share_pos: ## each shared pos
		normal_hap1, normal_hap2 = get_info_of_pos(normal_block, pos)
		this_tumor_hap1, this_tumor_hap2 = get_info_of_pos(tumor_block, pos)

		if normal_hap1 == this_tumor_hap1 and normal_hap2 == this_tumor_hap2:
			if n_h1_this is None:
				n_h1_this = 1
				n_h2_this = 2
			else:
				if n_h1_this != 1 or n_h2_this != 2: ## Error
					return False, None, None
			num_pos += 1
		elif normal_hap1 == this_tumor_hap2 and normal_hap2 == this_tumor_hap1:
			if n_h1_this is None: 
				n_h1_this = 2
				n_h2_this = 1
			else:
				if n_h1_this != 2 or n_h2_this != 1: ## Error
					return False, None, None
			num_pos += 1
		else: ## ignore this pos
			continue
	if num_pos < 2 : ## shared phasing snvs less than 2
		return False, None, None

	return True, n_h1_this, n_h2_this

def get_info_of_pos(block_list, pos):
	pos_idx = block_list['pos_list'].index(pos)
	hap1 = block_list['hap1list'][pos_idx]
	hap2 = block_list['hap2list'][pos_idx]
	return hap1, hap2


def get_share_blockindex(normal_pos_bindex, tumor_pos_bindex):
	'''
	key: tumor_index (chr_index)
	value: {normal_index: [pos], ...}
	'''
	share_block_index = {}

	share_pos = list(set(tumor_pos_bindex.keys()) & set(normal_pos_bindex.keys()))

	for pos in share_pos:
		n_idx = normal_pos_bindex[pos]
		t_idx = tumor_pos_bindex[pos]
		if t_idx in share_block_index:
			if n_idx in share_block_index[t_idx]:
				share_block_index[t_idx][n_idx].append(pos)
			else:
				share_block_index[t_idx][n_idx] = [pos]
		else:
			share_block_index[t_idx] = {}
			share_block_index[t_idx][n_idx] = [pos]

	return share_block_index

def write_blocks_stat(statf, blocks):
	with open(statf, 'w') as out:
		for chr in blocks:
			for index in blocks[chr]:
				block_start = blocks[chr][index]['block_start']
				block_end = blocks[chr][index]['block_end']
				block_len = block_end - block_start + 1
				phasing_snv_num = len(blocks[chr][index]['pos_list'])
				writer = '{0}\t{1}\t{2}\t{3}\t{4}\t{5}\n'.format(chr, index, block_start, block_end, block_len, phasing_snv_num)
				out.write(writer)

def write_json_blocks(outf, blocks_array):
	with open(outf, 'a') as out:
		for block in blocks_array:
			out.write(json.dumps(block))
			out.write('\n')

def run(args):
	if not os.path.exists(args.blocklist):
		raise ValueError('File not exists: {0}'.format(args.blocklist))
	merged_blocks, tumor_pos_bindex = run_extends_with_barcodes(args.blocklist, args.outfile)

	outf = '{0}.after.barcode.extends.stat'.format(args.outfile)
	write_blocks_stat(outf, merged_blocks)

	if args.normallist is not None:
		if not os.path.exists(args.normallist):
			raise ValueError('File not exists: {0}'.format(args.normallist))
		merged_blocks = run_extends_with_normal_block(args.normallist, merged_blocks, tumor_pos_bindex)
		outf = '{0}.after.normal.extends.stat'.format(args.outfile)
		write_blocks_stat(outf, merged_blocks)

	for ch in merged_blocks:
		write_json_blocks(args.outfile, merged_blocks[ch].values())
	


if __name__ == '__main__':
	parser = argparse.ArgumentParser()
	parser.add_argument('-b', '--blocklist', help='Input file: a file of block list', required=True)
	parser.add_argument('-n', '--normallist', help='Input file: a file of normal list', default=None)
	parser.add_argument('-o', '--outfile', help='Output file for result', default='extends.phasing')
	args = parser.parse_args()

	run(args)
