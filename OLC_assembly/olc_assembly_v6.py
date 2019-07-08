#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import re
import sys
import logging
import argparse

from Node import Node
from Edge import Edge, WeightDiedge
from Graph import DiGraph, DepthFirstPaths, EdgeWeightedDiGraph, DijkstraSP

def readFasta(infile):
	logging.info('Start read file: {0}'.format(infile))
	#if not (infile.endswith('.fa') or infile.endswith('.fasta')):
		#raise ValueError('Not fasta : {0}'.format(infile))
	raw_seq = []
	count = -1
	read_name = ""

	if infile is None:
		for line in sys.stdin:
			line_info = line.split('\t')
			flag = line_info[0]
			read_name = line_info[2].replace('@', '')
			new_node = Node(node_id=count, node_name=read_name, seq=line_info[3])
			raw_seq.append(new_node)
			count = count+1
	else:
		flag = os.path.basename(infile)
		#flag = os.path.splitext(basename)
		with open(infile, 'r') as f:
			for i in f:
				line = i.strip()
				if line.startswith('>'):
					count = count+1
					read_name = re.search(r'>(\S+)', line).group(1)
					new_node = Node(count, read_name, '')
					raw_seq.append(new_node)
				else:
					new_node.extendSeq(line)
	logging.info('Done')
	return flag, raw_seq

def findAllOverlap(node_array, o_len, n_mismatch=0):
	logging.info('Start find all overlap of pairs')
	overlapGrap = {}
	allNodes = {}
	for i in range(len(node_array)):
		for j in range(i+1, len(node_array), 1):
			node1 = node_array[i]
			node2 = node_array[j]
			f_ori, r_ori, start, len_overlap = overlapOfPair(node1, node2, n_mismatch)
			if f_ori:
				if len_overlap >= o_len:
					saveGraph(overlapGrap, allNodes, node1, node2, f_ori, r_ori, start, len_overlap)
	logging.info('Done')
	return overlapGrap, allNodes

def saveGraph(overlapGrap, allNodes, first_node, second_node, f_ori, r_ori, f_start, len_overlap):
	source_node, source_ori = splitOri(f_ori, first_node, second_node)
	target_node, target_ori = splitOri(r_ori, first_node, second_node)
	
	new_edge = Edge(source_node, target_node, source_ori, target_ori, f_start, len_overlap)
	edge_id = saveNodes(allNodes, new_edge)
	overlapGrap[edge_id] = new_edge
	logging.info('Edge: {0}\t{1}\t{2}\t{3}'.format(new_edge.From(), new_edge.To(), new_edge.source_start, len_overlap))

	new_rev_edge = new_edge.revEdge()
	edge_id = saveNodes(allNodes, new_rev_edge)
	overlapGrap[edge_id] = new_rev_edge
	logging.info('Edge: {0}\t{1}\t{2}\t{3}'.format(new_rev_edge.From(), new_rev_edge.To(), new_rev_edge.source_start, len_overlap))

def saveNodes(allNodes, edge):
	nodeName1 = edge.From()
	nodeName2 = edge.To()
	allNodes[nodeName1] = 1
	allNodes[nodeName2] = 1
	return '{0} {1}'.format(nodeName1, nodeName2)

def splitOri(ori, first_node, second_node):
	if ori[0] == '1':
		return first_node, ori[1]
	else:
		return second_node, ori[1]


def overlapOfPair(node1, node2, n_mismatch=0):
	node1_seq = node1.getSeq()
	node2_seq = node2.getSeq()
	#print('{2}:{0}\n{3}:{1}'.format(node1_seq, node2_seq, node1.getName(), node2.getName()))
	node2_reseq = node2.getRevcompSeq()

	a_array = {'1+':node1_seq}
	b_array = {'2+':node2_seq, '2-':node2_reseq}
	overlap_len = 0
	res = (None, None, None, None)
	for i in a_array:
		for j in b_array:
			start, ol = commonSubstring(a_array[i], b_array[j], n_mismatch)
			if not start == None and ol > overlap_len:
				res = (i, j, start, ol)
				overlap_len = ol

			startj, olj = commonSubstring(b_array[j], a_array[i], n_mismatch)
			if not startj == None and olj > overlap_len:
				res = (j, i, startj, olj)
				overlap_len = olj
	return res


def commonSubstring(a, b, n_mismatch=0):
	len_M = len(a)  #length of a
	len_N = len(b)  #length of b
	if n_mismatch == 0:
		cutoff_mismatch = 0
	else:
		cutoff_mismatch = int((len_M + len_N)*n_mismatch )+ 1
	for i in range(len(a)):
		j = 0 #end of b
		start = i
		len_overlap = 0
		mismatch = 0
		while(i < len_M and j < len_N):
			if a[i] != b[j]:
				mismatch += 1
				if mismatch > cutoff_mismatch:
					break
			len_overlap = len_overlap + 1
			#print('{0}, {1}, {2}'.format(i,j,len_overlap))
			i = i+1
			j = j+1
		if i == len_M :
			return start, len_overlap

	return None, None

def constructEdgeWeightedDiGraph(node_num, alledge, allnodes):
	logging.info('Start construct graph')
	graph = EdgeWeightedDiGraph(node_num, allnodes)
	for edge_id in alledge:
		graph.addEdge(alledge[edge_id])
	logging.info('Done')
	return graph

def findAllPaths(graph, search_method):
	logging.info('Start find all paths, search_method: {0}'.format(search_method))
	allpaths = []
	#leafNode = graph.findNodesWithOutdegree(0)
	rootNode = graph.findNodesWithIndegree(0)

	print('rooNodes:{0}'.format(rootNode))
	if search_method == 'DijkstraSP':
		paths = DijkstraSP(graph, rootNode)
	logging.info('Finished find paths')
	allpaths = paths.allPaths()
	logging.info('Done')
	return allpaths

def constructContig(allpaths):
	logging.info('Start construct contigs')
	contig_path = {}
	contig_node = []
	contigs = {}
	count = 0
	for path in allpaths:
		print('path:{0}'.format(path))
		start = -1
		consensus = {}
		for edge in path:
			list_1 = getSeqList(edge.source, edge.source_ori)
			list_2 = getSeqList(edge.target, edge.target_ori)

			tmp_s_path = '{0}{1}'.format(edge.source.getName(), edge.source_ori)
			tmp_t_path = '{0}{1}'.format(edge.target.getName(), edge.target_ori)

			source_start = edge.getSourceStart()
			if start == -1:
				lastA = appendConsensus(consensus, list_1, 0)
				contig_path[count] = [tmp_s_path]
				contig_node.append(edge.source.getId())
			start = source_start
			lastA = appendConsensus(consensus, list_2, start, lastA)
			contig_path[count].append(tmp_t_path)
			contig_node.append(edge.target.getId())

		contig = getConsensus(consensus)
		contigs[count] = contig
		count += 1
	logging.info('Done')
	return contigs, contig_path, contig_node

def getSeqList(node, ori):
	if ori == '+':
		return list(node.getSeq())
	else:
		return list(node.getRevcompSeq())

def getConsensus(consensus):
	list_consensus = []
	for pos in consensus:
		maxBase = max(consensus[pos], key = lambda x:consensus[pos][x])
		list_consensus.append(maxBase)
	return ''.join(list_consensus)

def appendConsensus(consensus, lista, start, refArray = []):
	lastA = []
	i = start
	for base in lista:
		if base != '-':
			if i < len(refArray):
				pos = refArray[i]
			else:
				if len(lastA) == 0:
					pos = 0
				else:
					pos = lastA[-1] + 1
			lastA.append(pos)
			if pos not in consensus:
				consensus[pos]={}
				consensus[pos]['A']=0
				consensus[pos]['T']=0
				consensus[pos]['G']=0
				consensus[pos]['C']=0
				consensus[pos]['N']=0
			consensus[pos][base] += 1
		i+=1
	return lastA

def singleNodesToContig(raw_seq, contigNodes, pathContigs, contigPaths ):
	logging.info('Start single Nodes')
	count = len(pathContigs)
	for seq in range(len(raw_seq)):
		if seq in contigNodes:
			continue
		pathContigs[count] = raw_seq[seq].getSeq()
		contigPaths[count] = ['{0}+'.format(raw_seq[seq].getName())]
		count += 1

def writeFiles(outf, writerDict, lineLen, prefix):
	with open (outf, 'w') as f:
		for item in writerDict:
			f.write('>Contig{0}#{2} len:{1}\n'.format(item, len(writerDict[item]), prefix))
			if lineLen == 0:
				f.write('{0}\n'.format(writerDict[item]))
			else:
				for i in range(0, len(writerDict[item]), 60):
					if i+60 < len(writerDict[item]):
						f.write(writerDict[item][i:i+60] + '\n')
					else:
						f.write(writerDict[item][i:] + '\n')

def runAssembly(infile=None, output_dir='./', num_overlap=5, rate_mismatch=0, seq_type='short'):
	basename, raw_seq = readFasta(infile)
	allEdge, allNodes = findAllOverlap(raw_seq, num_overlap, rate_mismatch)
	graph = constructEdgeWeightedDiGraph(len(allNodes), allEdge, allNodes)
	graph.printNetwork()
	allpaths = findAllPaths(graph, 'DijkstraSP')
	allContigs, allContigPaths, contigNodes = constructContig(allpaths)

	if(seq_type == 'long'):
		singleNodesToContig(raw_seq, contigNodes, allContigs, allContigPaths)
	
	contigf = os.path.join(output_dir, '{0}.contigs'.format(basename))
	writeFiles(contigf, allContigs, 60, basename)
	
	pathf = os.path.join(output_dir, '{0}.path'.format(basename))
	writeFiles(pathf, allContigPaths, 0, basename)

	return basename

if  __name__ == '__main__':
	parser = argparse.ArgumentParser()

	parser.add_argument('-i', '--input', help='Input file, fasta.(None)', default=None)
	parser.add_argument('-o', '--output_dir', help='Output directory.', required=True)
	parser.add_argument('-n', '--num_overlap', help='Minimum of overlap. (5)', default=5, type=int)
	parser.add_argument('-x', '--rate_mismatch', help='Frequence of mismatchs. (0)', default=0, type=float)
	parser.add_argument('-s', '--seq_type', help='Type of sequences.[short | long]', default='short')
	args = parser.parse_args()
	
	if args.input is None:
		basename = 'Olc_assembly'
	else:
		basename = os.path.basename(args.input)

	logf = os.path.join(args.output_dir, '{0}.log'.format(basename))
	#format = ('%(asctime)s - %(levelname)s — %(funcName)s: %(lineno)d — %(message)s')
	format = ('%(asctime)s - %(levelname)s: %(message)s')
	logging.basicConfig(level=logging.DEBUG, format=format, filename=logf, filemode='w')

	if args.seq_type == 'short':
		preflag = runAssembly(infile=args.input, output_dir=args.output_dir, num_overlap=args.num_overlap)
		runAssembly(infile=os.path.join(args.output_dir, '{0}.contigs'.format(preflag)), output_dir=args.output_dir, num_overlap=args.num_overlap, rate_mismatch=args.rate_mismatch, seq_type='long')
	else:
		runAssembly(infile=args.input, output_dir=args.output_dir, num_overlap=args.num_overlap, rate_mismatch=args.rate_mismatch, seq_type=args.seq_type)


