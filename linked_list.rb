# frozen_string_literal: true

require 'pry'
require 'pry-byebug'

# Listable#Deque: Coerce args to Deque
# => If Array, return new Deque with same values as Array
# => Else, initialize new Deque with all args as values
module Listable
  # rubocop:disable Naming/MethodName
  def Deque(*args)
    *args = *args.flatten
    Deque.new(*args)
  end
  # rubocop:enable Naming/MethodName
end

# Otherwise Listable is unusable
class Object
  include Listable
end

# Double Ended Queue implemented as Doubly Linked List
class Deque
  attr_reader :size

  def self.new(*args, len: args.size)
    deque = super()
    if args[0].class == Range
      deque.populate!(args[0])
    elsif len == args.size
      i = 0
      while i < len
        deque.push(args[i])
        i += 1
      end
    else
      j = 0
      while j < len
        i = 0
        while i < args.size
          deque.push(args[i])
          i += 1
        end
        j += 1
      end
    end
    deque
  end

  def initialize
    @head = nil
    @tail = nil
    @size = 0
  end

  def [](index, count = 0, node = head)
    return index_range(index) if index.class == Range
    return negative_idx(index) if index < 0
    return node.data if count == index
    return unless node.succ

    self[index, count + 1, node.succ]
  end

  def []=(idx, element)
    node_at(idx).data = element
  end

  def slice(beg_idx, n_idcs)
    result = Deque.new
    node = self[beg_idx]
    return unless node

    i = 0
    loop do
      break if i == n_idcs
      result.push(node)
      return result unless node.succ
      node = node.succ
      i += 1
    end
    result
  end

  def push(element)
    if head
      tail.append(element)
      self.tail = tail.succ
    else
      self.head = Node.new(element)
      self.tail = head
    end
    self.size += 1
    self
  end

  def pop
    return unless head

    data = tail.data
    second_to_last_node = tail.pred
    if second_to_last_node
      second_to_last_node.succ = nil
      self.tail = second_to_last_node
    else
      self.head = nil
      self.tail = nil
    end

    self.size -= 1
    data
  end

  def shift
    return unless head

    data = head.data
    self.head = head.succ
    self.tail = nil unless head

    self.size -= 1
    data
  end

  def unshift(element)
    node = Node.new(element, succ: head)
    head.pred = node if head
    self.head = node
    self.tail = node unless tail

    self.size += 1
    self
  end

  def inspect(node = head, str = '')
    return '(' + str + ')' unless node

    if str == ''
      str += node.to_s
    else
      str += (' <> ' + node.to_s)
    end
    inspect(node.succ, str)
  end

  def to_s(node = head, calr: caller[0][/`.*'/][1..-2].to_sym)
    if calr == :puts
      return '' unless head

      if node.succ
        puts node.data
        to_s(node.succ, calr: calr)
      else
        print node.data
        return ''
      end
    else
      inspect
    end
  end

  def each(&block)
    node = head
    while node
      block.call(node.data)
      node = node.succ
    end
    self
  end

  def each_with_index(&block)
    i = 0
    node = head
    until i == size
      block.call(node.data, i)
      node = node.succ
      i += 1
    end
    self
  end

  def map(&block)
    deque = Deque.new
    each { |e| deque.push block.call(e) }
    deque
  end

  def map_with_index(&block)
    deque = Deque.new
    each_with_index { |e, i| deque.push block.call(e, i) }
    deque
  end

  def map!(&block)
    node = head
    each do |e|
      node.data = block.call(e)
      node = node.succ
    end
  end

  def map_with_index!(&block)
    node = head
    each_with_index do |e, i|
      node.data = block.call(e, i)
      node = node.succ
    end
  end

  def select(&block)
    deque = Deque.new
    each { |e| deque.push(e) if block.call(e) }
    deque
  end

  def select_with_index(&block)
    deque = Deque.new
    each_with_index { |e, i| deque.push(e) if block.call(e, i) }
    deque
  end

  def select!(&block)
    node = head
    while node
      unless block.call(node.data)
        remove(node)
      end
      node = node.succ
    end
    self
  end

  def select_with_index!(&block)
    node = head
    i = 0
    while node
      unless block.call(node.data, i)
        remove(node)
      end
      node = node.succ
      i += 1
    end
    self
  end

  def delete(element)
    each_node do |node|
      if node.data == element
        remove(node)
        return node.data
      end
    end
    nil
  end

  def rdelete(element)

  end

  def delete_at(idx)
    node = node_at(idx)
    return nil unless node
    remove(node)
    node.data
  end

  def reduce(sum = nil, &block)
    return sum unless head
    if !sum
      sum = head.data
      return head.data unless head.succ
      node = head.succ
    else
      return sum unless head
      node = head
    end
    reducer(sum, node, &block)
  end

  def all?(&block)
    each { |e| return false unless block.call(e) }
    true
  end

  def all_with_index?(&block)
    each_with_index { |e, i| return false unless block.call(e, i) }
    true
  end

  def any?(&block)
    each { |e| return true if block.call(e) }
    false
  end

  def any_with_index?(&block)
    each_with_index { |e, i| return true if block.call(e, i) }
    false
  end

  def first
    head.data
  end

  def last
    tail.data
  end

  def <<(element)
    push(element)
  end

  def ==(other)
    return false unless other.class == Deque
    return false unless self.size == other.size
    all_with_index? { |e, i| e == other[i] }
  end

  def +(list)
    deque = deep_clone
    list.each { |e| deque.push(e) }
    deque
  end

  def deep_clone
    deque = Deque.new
    each { |e| deque.push(e) }
    deque
  end

  # Can only be called from Deque.new
  def populate!(range)
    method = caller[0][/`.*'/][1..-2].to_sym
    if method == :new
      unless range.class == Range
        raise TypeError.new("expected Range")
      end
      range.end.downto(range.begin) do |e|
        unshift(e)
      end
    else
      raise NoMethodError.new(
        "private method 'populate!' called for #{self}:#{self.class}"
      )
    end
  end

  def inspect_node(idx)
    puts node_at(idx).inspect
  end

  private

  attr_accessor :head, :tail
  attr_writer :size

  def node_at(idx, count = 0, node = head)
    return node_at_neg_idx(idx) if idx < 0
    return node if count == idx
    return unless node.succ
    node_at(idx, count + 1, node.succ)
  end

  def node_at_neg_idx(idx, count = -1, node = tail)
    return node if count == idx
    return unless node.pred

    node_at_neg_idx(idx, count - 1, node.pred)
  end

  def index_range(range)
    slice(range.begin, range.size)
  end

  def negative_idx(idx, count = -1, node = tail)
    return node.data if count == idx
    return unless node.pred

    negative_idx(idx, count - 1, node.pred)
  end

  def reducer(sum, node, &block)
    while node
      sum = block.call(sum, node.data)
      node = node.succ
    end
    sum
  end

  def remove(node)
    unless node.class == Deque::Node
      raise TypeError.new("expected #{Deque::Node}")
    end

    succ = node.succ
    pred = node.pred
    if succ
      succ.pred = pred
    else
      self.tail = pred
    end

    if pred
      pred.succ = succ
    else
      self.head = succ
    end

    self.size -= 1
    node
  end

  def each_node(&block)
    node = head
    while node
      block.call(node)
      node = node.succ
    end
    self
  end

  def each_node_with_index(&block) # SO FAR UNUSED
    i = 0
    node = head
    until i == size
      block.call(node, i)
      node = node.succ
      i += 1
    end
    self
  end

  class Node
    attr_accessor :data, :pred, :succ

    def initialize(data, pred: nil, succ: nil)
      @data = data
      @pred = pred
      @succ = succ
    end

    def append(element)
      self.succ = Node.new(element, pred: self, succ: succ)
    end

    def to_s
      return data.to_s if data

      'nil'
    end

    def inspect
      return "[#{pred} <= #{data} => #{succ}]" if pred && succ && data
      return "[#{pred} <= nil => #{succ}]" if pred && succ && !data
      return "[Head: #{data} => #{succ}]" if !pred && succ
      "[#{pred} <= #{data} :Tail]" if pred && !succ
    end
  end
end

# p deque = Deque.new(1, 2, 3, 4, 5, 'a')
#
# p Deque(1, 2, 3, 4, 9, 7)
#
# p Deque([1, 2, 3, 4, 9, 7])
#
# p Deque()
#
# deque = Deque.new(0..9)
# p deque
# deque[5] = 'T'
# p deque

deque = Deque.new(1..9)
p deque
p deque.delete(5)
p deque

# deque[-1] = 8
# p deque
# p deque + Deque(7)
# p deque
# p list
# p deque == list
# p deque.size

# deque = Deque.new('a', 'b', 'c', len: 3)
# p deque
# p Deque.new('a', 'b', 'c', 'd')
# nums = Deque.new(10, len: 5) #{ |e| e = e * 2 }
# p nums

# deque = Deque.new
# deque.unshift('f')
# deque.unshift('e')
# deque.unshift('d')
# deque.unshift(nil)
# deque.unshift('b')
# deque.unshift('a')
#
# deque = Deque.new(1..9)
# p deque[8]

# p deque[5]
# p deque[-6]
# p deque.slice(0, 5)
# p deque
# p deque[-3..-1]
# p deque[-3..5]
# p deque[3..5]
# p deque.push(10)
# p deque.unshift(20)
# p deque.pop
# p deque
