#!/usr/bin/env python
# -*- coding: utf-8 -*-

import numpy as np

class DynamicProgramming(object):
	def __init__(self, penalty_match=5, penalty_mismatch=-1, penalty_gap=-10, sequenceM='', sequenceN='', Mname='', Nname='', solution=True):
		self._penalty_match = penalty_match
		self._penalty_mismatch = penalty_mismatch
		self._penalty_gap = penalty_gap
		self._sequenceM = sequenceM
		self._sequenceN = sequenceN
		self.seqMname = Mname
		self.seqNname = Nname
		self._scoreMatrix = np.zeros((len(sequenceN)+1, len(sequenceM)+1))
		self._goTo = {}
		if solution:
			self._solution()

	def _solution(self):
		for i in range(len(self._sequenceN)+1):
			for j in range(len(self._sequenceM)+1):
				if i == 0 and j == 0:
					continue
				elif i == 0:
					self._scoreMatrix[i][j] = self._scoreMatrix[i][j-1] + self._penalty_gap
					self._appendGoTo(i, j, 'y_gap')

				elif j == 0:
					self._scoreMatrix[i][j] = self._scoreMatrix[i-1][j] + self._penalty_gap
					self._appendGoTo(i, j, 'x_gap')

				else:
					y_gap = self._scoreMatrix[i][j-1] + self._penalty_gap
					x_gap = self._scoreMatrix[i-1][j] + self._penalty_gap
					
					if self._sequenceM[j-1] == self._sequenceN[i-1]:
						align = self._scoreMatrix[i-1][j-1] + self._penalty_match
						aligntype = 'match'
					else:
						align = self._scoreMatrix[i-1][j-1] + self._penalty_mismatch
						aligntype = 'mismatch'

					maxscore, maxtype = self._maxOne(y_gap, x_gap, align, aligntype)
					self._scoreMatrix[i][j] = maxscore
					self._appendGoTo(i, j, maxtype)

	
	def getIndex(self, i, j):
		return i*(1+len(self._sequenceM)) + j
	
	def _maxOne(self, y_gap, x_gap, align, aligntype):
		if x_gap < align:
			maxscore = align
			maxtype = aligntype
		else:
			maxscore = x_gap
			maxtype = 'x_gap'

		if y_gap > maxscore:
			maxscore = y_gap
			maxtype = 'y_gap'

		return maxscore,maxtype
	
	def _appendGoTo(self, i, j, maxtype):
		if maxtype == 'y_gap':
			index_from = self.getIndex(i, j-1)
		elif maxtype == 'x_gap':
			index_from = self.getIndex(i-1, j)
		else:
			index_from = self.getIndex(i-1, j-1)
		index_to = self.getIndex(i,j)
		self._goTo[index_to] = [index_from, maxtype]
	
	def indexToCoordinate(self, index):
		i = int(index / (len(self._sequenceM)+1))
		j = index % (len(self._sequenceM) + 1)
		#print('{0} = {1} % {2}'.format(j, index, len(self._sequenceM)))
		return i,j

	def printScoreMatrix(self):
		print(self._scoreMatrix)
	
	def printGoTo(self):
		for i in self._goTo:
			ii, ij = self.indexToCoordinate(i)
			qi, qj = self.indexToCoordinate(self._goTo[i][0])
			print('{0},{1} -> {2},{3} : {4}'.format(qi, qj, ii, ij, self._goTo[i][1]))
	
	def maxScore(self):
		return self._scoreMatrix.max(), np.argmax(self._scoreMatrix)
	
	def goTo(self, index=-1, i=-1, j=-1):
		if index == -1 and (i==-1 or j==-1):
			return None
		elif index == -1:
			index = self.getIndex(i,j)
		return self._goTo[index]

	def localAlign(self):
		maxScore, maxIndex = self.maxScore()
		alignment = Alignment(Type='local', alignScore=maxScore, SeqM=self._sequenceM, SeqN=self._sequenceN, seqMname=self.seqMname, seqNname=self.seqNname)
		alignment.setAlignEndIndex(maxIndex)

		index = maxIndex
		while index in self._goTo:
			index_from = self._goTo[index][0]
			alignType = self._goTo[index][1]
			alignment.appendAlignType(index, alignType)
			index = index_from

			i, j = self.indexToCoordinate(index_from)
			if i == 0:
				break
			if j == 0:
				break
		alignment.setAlignStartIndex(index)
		return alignment

	def globalAlign(self):
		score = self._scoreMatrix[len(self._sequenceN)][len(self._sequenceM)]
		index = self.getIndex(len(self._sequenceN), len(self._sequenceM))
		alignment = Alignment(Type='global', alignScore=score, SeqM=self._sequenceM, SeqN=self._sequenceN, seqMname=self.seqMname, seqNname=self.seqNname)
		alignment.setAlignEndIndex(index)

		while index in self._goTo:
			index_from = self._goTo[index][0]
			alignType = self._goTo[index][1]
			alignment.appendAlignType(index, alignType)
			index = index_from
		alignment.setAlignStartIndex(index)

		return alignment

class Alignment(object):
	def __init__(self, Type='local', alignScore=0, SeqM='', SeqN='', alignStart=0, alignEnd=0, seqMname='', seqNname=''):
		self._alintype = Type
		self.alignStartIndex = alignEnd
		self.alignEndIndex = alignStart
		self._xGap = []
		self._yGap = []
		self._misMatch = []
		self._lenSeqM = len(SeqM)
		self._lenSeqN = len(SeqN)
		self._seqM = SeqM
		self._seqN = SeqN
		self._seqMname = seqMname
		self._seqNname = seqNname
		self.alignScore = alignScore
	
	def _indexToCoordinate(self, index):
		i = int(index / (self._lenSeqM+1))
		j = index % (self._lenSeqM + 1)
		return i,j

	def alignType(self):
		return self._alintype

	def alignStartCoordinate(self):
		return self._indexToCoordinate(self.alignStartIndex)
	
	def alignEndCoordinate(self):
		return self._indexToCoordinate(self.alignEndIndex)

	def setAlignStartIndex(self, sindex):
		self.alignStartIndex = sindex
	
	def setAlignEndIndex(self, eindex):
		self.alignEndIndex = eindex
	
	def appendAlignType(self, index, alignType):
		if alignType == 'y_gap':
			self.appendYgap(index)
		elif alignType == 'x_gap':
			self.appendXgap(index)
		elif alignType == 'mismatch':
			self.appendMismatch(index)

	def appendXgap(self, xgapindex):
		i, j = self._indexToCoordinate(xgapindex)
		self._xGap.append(j)
	
	def xgapNum(self):
		return len(self._xGap)
	
	def xgap(self):
		return self._xGap

	def appendYgap(self, ygapindex):
		i, j = self._indexToCoordinate(ygapindex)
		self._yGap.append(i)
	
	def ygapNum(self):
		return len(self._yGap)
	
	def ygap(self):
		return self._yGap
	
	def gapNum(self):
		return len(self._xGap) + len(self._yGap)
	
	def appendMismatch(self, index):
		self._misMatch.append(index)
	
	def mismatchNum(self):
		return len(self._misMatch)
	
	def mismatch(self):
		return self._misMatch
	
	def seqM_name(self):
		return self._seqMname
	
	def seqN_name(self):
		return self._seqNname
	
	def source(self):
		startI, startJ = self.alignStartCoordinate()
		if startI < startJ:
			return startJ, self._seqMname
		else:
			return startI, self._seqNname
	
	def target(self):
		startI, startJ = self.alignStartCoordinate()
		if startI < startJ:
			return startI, self._seqNname
		else:
			return startJ, self._seqMname
	
	# 1 : seqM equal seqN
	# 2 : seqM overlap with seqN (left)
	# 3 : seqM overlap with seqN (right)
	# 4 : seqM overlap with seqN (center)
	# 5 : seqM link seqN 
	# 6 : seqN link seqM
	# 7 : seqM contain seqN
	# 8 : seqN contain seqM
	# 9 : other
	def linkType(self):
		typeDict = {
				'1-1':4, '1-2':9, '1-3':9, '1-4':7,
				'2-1':9, '2-2':2, '2-3':6, '2-4':7,
				'3-1':9, '3-2':5, '3-3':3, '3-4':7,
				'4-1':8, '4-2':8, '4-3':8, '4-4':1,
				}

		startI, startJ = self.alignStartCoordinate()
		endI, endJ = self.alignEndCoordinate()
		
		seqMtype = self._seqAlignType(startJ, endJ, self._lenSeqM)
		seqNtype = self._seqAlignType(startI, endI, self._lenSeqN)
		
		M_Ntype = '{0}-{1}'.format(seqMtype, seqNtype)
		return typeDict[M_Ntype]

	#1:center
	#2:left
	#3:right
	#4:full
	def _seqAlignType(self, start, end, seqLen):
		if start == 0 and end == seqLen:
			return 4
		elif start == 0:
			return 2
		elif end == seqLen:
			return 3
		else:
			return 1
	
	def displayAlign(self):
		list_M = self.listAlignM()
		list_N = self.listAlignN()

		startI, startJ = self.alignStartCoordinate()

		if self._alintype == 'local':
			if startI < startJ:
				list_N.insert(0, ' '*(startJ-startI))
			elif startJ < startI:
				list_M.insert(0, ' '*(startI-startJ))
		
		endI, endJ = self.alignEndCoordinate()
		string = ' '*max(startI, startJ) + '|'*(endJ-startJ)

		print(''.join(list_M))
		print(string)
		print(''.join(list_N))
			
	def listAlignM(self):
		list_M = list(self._seqM)
		for s in self._xGap:
			list_M.insert(s, '-')
		return list_M
	
	def listAlignN(self):
		list_N = list(self._seqN)
		for s in self._yGap:
			list_N.insert(s, '-')
		return list_N
	
	def listAlign(self):
		list_M = list(self._seqM)
		list_N = list(self._seqN)

		for s in self._xGap:
			list_M.insert(s, '-')

		for s in self._yGap:
			list_N.insert(s, '-')

		startI, startJ = self.alignStartCoordinate()
		if startI < startJ: ## frist seq -> seqM
			return list_M, list_N
		else:
			return list_N, list_M


class SmithWaterman(DynamicProgramming):
	def __init__(self, penalty_match=5, penalty_mismatch=-5, penalty_gap=-6, sequenceM='', sequenceN='', Mname='', Nname=''):
		DynamicProgramming.__init__(self, penalty_match, penalty_mismatch, penalty_gap, sequenceM, sequenceN, Mname, Nname, solution=False)
		self._SW_solution()

	def _SW_solution(self):
		for i in range(len(self._sequenceN)+1):
			for j in range(len(self._sequenceM)+1):
				score = {}
				score['stop'] = 0
				if i == 0 or j == 0:
					continue
				else:
					y_gap = self._scoreMatrix[i][j-1] + self._penalty_gap
					score['y_gap'] = y_gap
					x_gap = self._scoreMatrix[i-1][j] + self._penalty_gap
					score['x_gap'] = x_gap

					if self._sequenceM[j-1] == self._sequenceN[i-1]:
						align = self._scoreMatrix[i-1][j-1] + self._penalty_match
						score['match'] = align
					else:
						align = self._scoreMatrix[i-1][j-1] + self._penalty_mismatch
						score['mismatch'] = align
				
				maxtype, maxscore = max(score.items(), key = lambda x:x[1])
				self._scoreMatrix[i][j] = maxscore
				self._appendGoTo(i, j, maxtype)
	
	def _appendGoTo(self, i, j, maxtype):
		if maxtype == 'y_gap':
			index_from = self.getIndex(i, j-1)
		elif maxtype == 'x_gap':
			index_from = self.getIndex(i-1, j)
		elif maxtype == 'stop':
			return
		else:
			index_from = self.getIndex(i-1, j-1)
		index_to = self.getIndex(i,j)
		self._goTo[index_to] = [index_from, maxtype]
