import heapq

class IndexMaxPQ:
	def __init__(self):
		self.__queue = []
		self.__index = 0
	
	def push(self, item_name, priority):
		heapq.heappush(self.__queue, [-priority, self.__index, Item(item_name)])
		self.__index += 1
	
	def pop(self):
		return heapq.heappop(self.__queue)[-1]

	def printQ(self):
		string = ''
		for item in self.__queue:
			string = string + item[2].name
		print(string)
	
	def qsize(self):
		return len(self.__queue)

	def isEmpty(self):
		if len(self.__queue) == 0:
			return True
		return False

	def contain(self, item_name):
		for q in self.__queue:
			if q[2].name == item_name:
				return True
		return False

	def change(self, item_name, priority):
		for q in self.__queue:
			if q[2].name == item_name:
				self.__queue.remove(q)
				self.push(item_name, priority)
				break

class Item:
	def __init__(self, name):
		self.name = name
	
	def __repr__(self):
		return 'Item({!r})'.format(self.name)

