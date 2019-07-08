from Node import Node
from Align import Alignment
class Edge(object):
	def __init__(self, source=Node(), target=Node(), source_ori='+', target_ori='+', source_start=0, overlap_len=0):
		self.source = source
		self.target = target
		self.source_ori = source_ori
		self.target_ori = target_ori
		self.source_start = source_start
		self.overlap_len = overlap_len

	def getSource(self):
		return self.source

	def getTarget(self):
		return self.target

	def getSourceOri(self):
		return self.source_ori

	def getTargetOri(self):
		return self.target_ori
	
	def getSourceStart(self):
		return self.source_start

	def getOverlapLength(self):
		return self.overlap_len

	def From(self):
		return '{0}{1}'.format(self.source.node_id, self.source_ori)

	def To(self):
		return '{0}{1}'.format(self.target.node_id, self.target_ori)

	def getWeight(self):
		weight = 0.6 * (self.overlap_len) + 0.4 * (self.target.getSeqLen() - self.overlap_len)
		return weight

	def reverse(self):
		edge = Edge(self.target, self.source, self.target_ori, self.source_ori, 0, self.overlap_len)
		return edge

	def getOverlapSeq(self):
		if self.source_ori == "+":
			return self.source.seq[self.source_start:self.source_start+self.overlap_len]
		else:
			return self.source.getRevcompSeq()[self.source_start:self.source_start+self.overlap_len]
	
	def revOri(self, ori):
		if ori == '+':
			return '-'
		else:
			return '+'

	def revEdge(self):
		source1 = self.target
		target1 = self.source
		source_ori1 = self.revOri(self.target_ori)
		target_ori1 = self.revOri(self.source_ori)
		source_start1 = self.target.getSeqLen() - self.overlap_len
		return Edge(source=source1, target=target1, source_ori=source_ori1, target_ori=target_ori1, source_start=source_start1, overlap_len=self.overlap_len)
	
	def __str__(self):
		source_node_name = self.source.node_name
		target_node_name = self.target.node_name
		return '{0}\t{1}\t{2}\t{3}\t{4}'.format( source_node_name + self.source_ori, target_node_name + self.target_ori, self.source_start, self.overlap_len, self.getWeight())

class WeightDiedge(Edge):
	def __init__(self, source=Node(), target=Node(), source_ori='+', target_ori='+', source_start=0, overlap_len=0, weight=0):
		Edge.__init__(self, source, target, source_ori, target_ori, source_start, overlap_len)
		self.__weight = weight
	
	def getWeight(self):
		return self.__weight
	
	def revEdge(self):
		source1 = self.target
		target1 = self.source
		source_ori1 = self.revOri(self.target_ori)
		target_ori1 = self.revOri(self.source_ori)
		source_start1 = self.target.getSeqLen() - self.overlap_len
		return WeightDiedge(source=source1, target=target1, source_ori=source_ori1, target_ori=target_ori1, source_start=source_start1, overlap_len=self.overlap_len, weight=self.__weight)
	
class AlignEdge(object):
	def __init__(self, alignment):
		self.__source_start, self.__source_name = alignment.source()
		self.__target_start, self.__target_name = alignment.target()
		self.__alignment = alignment
	
	def getAlign(self):
		return self.__alignment
	
	def From(self):
		return self.__source_name
	
	def To(self):
		return self.__target_name

	def getWeight(self):
		return 1
	
	def __str__(self):
		string = '{0}->{1}\n{2}'.format(self.__source_name, self.__target_name, self.__alignment.displayAlign())
		return string
