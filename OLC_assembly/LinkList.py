#!/usr/bin/env python
# -*- coding: utf-8 -*-

class LinkNode(object):
	"""节点"""
	def __init__(self, elem=None):
		self.elem = elem
		self.next = None  # 初始设置下一节点为空

class SingleLinkList(object):
	"""单链表"""
	def __init__(self, node=None):  # 使用一个默认参数，在传入头结点时则接收，在没有传入时，就默认头结点为空
		self.__head = node
	
	def is_empty(self):
		return self.__head == None
	
	def length(self):
		# cur游标，用来移动遍历节点
		cur = self.__head
		# count记录数量
		count = 0
		while cur != None:
			count += 1
			cur = cur.next
		return count
	
	def travel(self):
		'''遍历整个列表'''
		cur = self.__head
		while cur != None:
			print(cur.elem, end=' ')
			cur = cur.next
		print("\n")
	
	def add(self, item):
		'''链表头部添加元素'''
		node = LinkNode(item)
		node.next = self.__head
		self.__head = node
	
	def append(self, item):
		'''链表尾部添加元素'''
		node = LinkNode(item)
		# 由于特殊情况当链表为空时没有next，所以在前面要做个判断
		if self.is_empty():
			self.__head = node
		else:
			cur = self.__head
			while cur.next != None:
				cur = cur.next
			cur.next = node
	
	def insert(self, pos, item):
		if pos <= 0:
			self.add(item)
		else:
			per = self.__head
			count = 0
			while count < pos - 1:
				count += 1
				per = per.next
			node = LinkNode(item)
			node.next = per.next
			per.next = node
	
	def remove(self, item):
		cur = self.__head
		pre = None
		while cur != None:
			if cur.elem == item:
				if cur == self.__head:
					self.__head = cur.next
				else:
					pre.next = cur.next
				break
			else:
				pre = cur
				cur = cur.next
	
	def search(self, item):
		cur = self.__head
		while not cur:
			if cur.elem == item:
				return True
			else:
				cur = cur.next
			return False
	
