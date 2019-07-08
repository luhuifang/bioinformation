#from string import maketrans
class Node(object):
	def __init__(self , node_id=None, node_name=None, seq=''):
		self.node_id = node_id
		self.node_name = node_name
		self.seq = seq
	
	def getId(self):
		return self.node_id
	
	def getName(self):
		return self.node_name
	
	def getSeq(self):
		return self.seq
	
	def getRevcompSeq(self):
		return self.__revcomp()
	
	def getSeqLen(self):
		return len(self.seq)
	
	def extendSeq(self, sequence):
		self.seq = self.seq + sequence
	
	def __str__(self):
		return '{0}\t{1}\t{2}'.format(self.node_id, self.node_name, self.seq)

	def __complement(self, seq):
		return seq.translate(str.maketrans('ATCGatcg', 'TAGCtagc'))
	
	def __revcomp(self):
		return self.__complement(self.seq)[::-1]

