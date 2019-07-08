#!/usr/bin/env python
# -*- coding: utf-8 -*-

from Edge import Edge, AlignEdge
from Queue import IndexMaxPQ
class DiGraph(object):
	def __init__(self, num_node, nodes=[], num_edge=0):
		self.num_node = num_node
		self.num_edge = num_edge
		self.adj = {}
		self.indegree = {}
		self.outdegree = {}
		
		if len(nodes) >0:
			for v in nodes:
				#print('nodes:{0}'.format(v))
				self.adj[v] = []
				self.indegree[v] = 0
				self.outdegree[v] = 0
		else:
			for v in range(num_node):
				#print('num_node:{0}'.format(v))
				self.adj[v] = []
				self.indegree[v] = 0
				self.outdegree[v] = 0


	def V(self):
		return self.num_node
	
	def E(self):
		return self.num_edge
	
	def addEdge(self, source_id, target_id):
		self.adj[source_id].append(target_id)
		self.num_edge += 1
		self.outdegree[source_id] += 1
		self.indegree[target_id] += 1

	def adjNodes(self, v):
		return self.adj[v]
	
	def hasAdj(self, v):
		if len(self.adj[v])==0:
			return False
		return True
	
	def reverse(self):
		R = DiGraph(self.num_node)
		for v in self.adj:
			for w in self.adj[v]:
				R.addEdge(w, v)
		return R
	
	def getIndegree(self, v):
		return self.indegree[v]
	
	def getOutdegree(self, v):
		return self.outdegree[v]

	def isSingleNode(self, v):
		if self.indegree[v] == 0 and self.outdegree[v] == 0:
			return True
		return False

	def isRoot(self, v):
		if self.indegree[v] == 0:
			return True
		return False
	
	def isLeaf(self, v):
		if self.outdegree[v] == 0:
			return True
		return False
	
	def findAllSingleNodes(self):
		singlenodes = []
		for v in self.indegree:
			#print('foreach {0}, indegree: {1}; outdegree: {2}'.format(v, self.indegree[v], self.outdegree[v]))
			if self.isRoot(v) and self.isLeaf(v):
				singlenodes.append(v)
		return singlenodes
	
	def findNodesWithIndegree(self, indegree):
		nodes = []
		for v in self.indegree:
			if self.indegree[v] == indegree:
				nodes.append(v)
		return nodes
	
	def findNodesWithOutdegree(self, outdegree):
		nodes = []
		for v in self.outdegree:
			if self.outdegree[v] == outdegree:
				nodes.append(v)
		return nodes
	
	def printNetwork(self):
		for v in self.adj:
			for adjv in self.adj[v]:
				print('{0}\t{1}'.format(v, adjv))

	def __str__(self):
		graph_str = '{0} vertices, {1} edges\n'.format(self.V(), self.E())
		for v in self.adj:
			graph_str = graph_str + '{0} : {1}'.format(v, adj[v])
		return graph_str

class EdgeWeightedDiGraph(DiGraph):
	def __init__(self, num_node, nodes=[], num_edge=0):
		DiGraph.__init__(self, num_node, nodes, num_edge)
	
	def addEdge(self, edge):
		self.adj[edge.From()].append(edge)
		self.num_edge += 1
		self.outdegree[edge.From()] += 1
		self.indegree[edge.To()] += 1

	def reverse(self):
		R = EdgeWeightedDiGraph(self.num_node)
		for v in self.adj:
			R.addEdge(v.reverse())
		return R
	
	def edges(self):
		edges = []
		for v in adj:
			edges.append(adj[v])
		return edges

	def printNetwork(self):
		for v in self.adj:
			for adje in self.adj[v]:
				print('{0}\t{1}'.format(adje.From(), adje.To()))

class DepthFirstPaths(object):
	def __init__(self, graph, start):
		self.s = start
		self.endTo = {}
		self.marked = {}
		self.dfs(graph, start)
	
	def dfs(self, graph, start):
		#print('sarch node {0}'.format(start))
		self.marked[start] = True
		if graph.hasAdj(start):
			#print('adj: {0}'.format(graph.adjNodes(start)))
			for w in graph.adjNodes(start):
				if not w in self.marked:
					self.endTo[w] = start
					self.dfs(graph, w)
	
	def hasPathTo(self, end):
		if end in self.marked:
			return True
		return False
		#return self.marked[end]
	
	def pathTo(self, node_id):
		if self.hasPathTo(node_id):
			x = node_id
			path = []
			while(x != self.s):
				path.append(x)
				x = self.endTo[x]
			path.append(self.s)
			path.reverse()
			return path

class DijkstraSP(object):
	def __init__(self, edgeWeightedDigraph, startNodes=[] ):
		self.startNodes = startNodes
		self.edgeTo = {}
		self.distTo = {}
		self.pq = IndexMaxPQ()

		if self.startNodes:
			for s in self.startNodes:
				self.hasStarted = []
				self.distTo[s] = 0.0
				self.pq.push(s, 0.0)
				while not self.pq.isEmpty():
					self.relax(edgeWeightedDigraph, self.pq.pop())

	def relax(self, edgeWeightedDigraph, item_obj):
		start_v = item_obj.name
		self.hasStarted.append(start_v)
		print('start_v:{0}'.format(start_v))
		for adj_edge in edgeWeightedDigraph.adj[start_v]:
			w = adj_edge.To()
			#print('adj: to {0}, edge {1}'.format(w, adj_edge))
			if w in self.hasStarted: #cycle
				continue
			if (w not in self.distTo) or (self.distTo[w] < self.distTo[start_v] + adj_edge.getWeight()):
				self.distTo[w] = self.distTo[start_v] + adj_edge.getWeight()
				self.edgeTo[w] = adj_edge
				if self.pq.contain(w):
					self.pq.change(w, self.distTo[w])
				else:
					self.pq.push(w, self.distTo[w])
		self.pq.printQ()

	def getDistTo(self, v):
		return self.edgeTo[v]
	
	def hasPathTo(self, v):
		if v in self.distTo:
			return True
		else:
			return False
	
	def pathTo(self, v):
		if not self.hasPathTo(v):
			return None
		path = []
		e = v
		while e in self.edgeTo:
			path.append(self.edgeTo[e])
			e = self.edgeTo[e].From()
		path.reverse()
		return path

	def maxDist(self):
		sortedDist = sorted(self.distTo.items(), key=lambda item:item[1], reverse=True)
		return sortedDist[0]
	
	def allPaths(self):
		dists = self.distTo
		edges = self.edgeTo
		paths = []
		while len(dists) > 0 :
			maxdistV, maxdist = max(dists.items(), key=lambda item:item[1])
			print('maxdistV:{0}, maxdist:{1}'.format(maxdistV, maxdist))
			path = []
			e = maxdistV
			vs = []

			if maxdist > 0:
				while e in edges:
					print('go to: {0}'.format(e))
					w = edges[e].From()
					#vs.append(e)
					if w in dists :
						path.append(edges[e])
						
					del dists[e]
					if self.__rev_v(e) in dists:
						del dists[self.__rev_v(e)]
					#add
					del edges[e]
					if self.__rev_v(e) in edges:
						del edges[self.__rev_v(e)]

					e = w
				#vs.append(e)
				if e in dists:
					del dists[e]
				if self.__rev_v(e) in dists:
					del dists[self.__rev_v(e)]

				if len(path) > 0:
					path.reverse()
					paths.append(path)
			else:
				del dists[e]
			
			'''
			for v in vs:
				if v in dists:
					del dists[v]
				if self.__rev_v(v) in dists:
					del dists[self.__rev_v(v)]
			'''

		return paths
	
	def __rev_v(self, v):
		if v.endswith('+'):
			return v.replace('+', '-')
		elif v.endswith('-'):
			return v.replace('-', '+')
		return v

