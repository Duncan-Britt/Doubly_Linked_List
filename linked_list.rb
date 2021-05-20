# frozen_string_literal: true

require 'pry'
require 'pry-byebug'
require 'benchmark'

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

  def length
    size
  end

  def self.new(*args, len: nil)
    deque = super()
    if args[0].class == Range
      deque.populate!(args[0])
    elsif len == nil
      i = 0
      while i < args.size
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

  def append(element)
    push(element)
  end

  def collect(&block)
    map(&block)
  end

  def count(*arg)
    return size if arg.empty?
    if arg.size != 1
      raise ArgumentError.new(
        "wrong number of arguments (given 2, expected 0..1)"
      )
    end
    amt = 0
    each { |e| amt += 1 if arg[0] == e }
    amt
  end

  def deep_clone
    deque = Deque.new
    each { |e| deque.push(e) }
    deque
  end

  def delete(element)
    included = false
    select! do |e|
      if e != element
        true
      else
        included = true
        false
      end
    end
    if included
      element
    else
      nil
    end
  end

  def delete_at(idx)
    node = node_at(idx)
    return nil unless node
    remove(node)
    node.data
  end

  def drop(num)
    raise ArgumentError.new("attempt to drop negative size") if num < 0
    return Deque.new if num >= size
    slice(num, -1)
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

  def empty?
    !head
  end

  def fdelete(element)
    each_node do |node|
      if node.data == element
        remove(node)
        return node.data
      end
    end
    nil
  end

  def find(value)
    index(value)
  end

  def find_all(value)
    count = 0
    indeces = Deque.new
    node = head
    loop do
      return indeces unless node
      indeces.push(count) if value == node.data
      count += 1
      node = node.succ
    end
  end

  def first
    head.data
  end

  def flatten
    deque = Deque.new

    node = head
    contains_deque = false
    while node
      if node.data.class != Deque
        deque.push(node.data)
      else
        node.data.each do |e|
          if e.class != Deque
            deque.push(e)
          else
            contains_deque = true
            deque.push(e)
          end
        end
      end
      node = node.succ
    end
    if contains_deque
      deque.flatten
    else
      deque
    end
  end

  def flatten!
    node = head
    contains_deque = false
    while node
      if node.data.class == Deque
        node.data.each do |e|
          if e.class != Deque
            push(e)
          else
            contains_deque = true
            push(e)
          end
        end
      end
      node = node.succ
    end
    if contains_deque
      flatten
    else
      deque
    end
  end

  def include?(element)
    each { |e| return true if element == e }
    false
  end

  def index(value, count = 0, node = head)
    return nil unless node
    return count if value == node.data
    index(value, count + 1, node.succ)
  end

  def inject(&block)
    reduce(&block)
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

  def inspect_node(idx)
    puts node_at(idx).inspect
  end

  def last
    tail.data
  end

  def ldelete(element)
    reverse_each_node do |node|
      if node.data == element
        remove(node)
        return node.data
      end
    end
    nil
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

  def max
    return nil unless head

    m = head.data
    each { |e| m = e if e > m }
    m
  end

  def max_by(&block)
    return nil unless head

    m = head.data
    each { |e| m = e if block.call(m) < block.call(e) }
    m
  end

  def min
    return nil unless head

    m = head.data
    each { |e| m = e if e < m }
    m
  end

  def min_by(&block)
    return nil unless head

    m = head.data
    each { |e| m = e if block.call(m) > block.call(e) }
    m
  end

  def minmax
    return nil unless head

    min = head.data
    max = head.data
    each do |e|
      min = e if e < min
      max = e if e > max
    end
    Deque.new(min, max)
  end

  def none?(&block)
    each { |e| return false if block.call(e) }
    true
  end

  def none_with_index?(&block)
    each_with_index { |e, i| return false if block.call(e, i) }
    true
  end

  def one?(&block)
    count = 0
    each do |e|
      count += 1 if block.call(e)
      return false if count == 2
    end
    count == 1
  end

  def one_with_index?(&block)
    count = 0
    each_with_index do |e, i|
      count += 1 if block.call(e, i)
      return false if count == 2
    end
    count == 1
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

  def prepend(element)
    unshift(element)
  end

  def product(*args)
    if args.size == 1
      result = Deque.new
      each do |e|
        args[0].each do |f|
          result << Deque.new(e, f)
        end
      end
      result
    else
      temp = args[0].product(*args[1..-1])
      result = Deque.new
      each do |e|
        temp.each do |f|
          result << (Deque.new(e) + f)
        end
      end
      result
    end
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

  def reject(&block)
    deque = Deque.new
    each { |e| deque.push(e) unless block.call(e) }
    deque
  end

  def reject!(&block)
    node = head
    while node
      if block.call(node.data)
        remove(node)
      end
      node = node.succ
    end
    self
  end

  def reject_with_index(&block)
    deque = Deque.new
    each_with_index { |e, i| deque.push(e) unless block.call(e) }
    deque
  end

  def reject_with_index!(&block)
    node = head
    i = 0
    while node
      if block.call(node.data, i)
        remove(node)
      end
      node = node.succ
      i += 1
    end
    self
  end

  def reverse
    deque = Deque.new
    each { |e| deque.unshift(e) }
    deque
  end

  def reverse!
    i = 0
    beg_node = head
    end_node = tail
    until i == size / 2
      node_swap(beg_node, end_node)
      succ = end_node.succ
      pred = beg_node.pred
      beg_node = succ
      end_node = pred
      i += 1
    end
    self
  end

  def reverse_each(&block)
    node = tail
    while node
      block.call(node.data)
      node = node.pred
    end
    self
  end

  def rindex(value, count = size - 1, node = tail)
    return nil unless node
    return count if value == node.data
    rindex(value, count - 1, node.pred)
  end

  def sample
    self[rand(size)]
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

  def shift
    return unless head

    data = head.data
    self.head = head.succ
    self.tail = nil unless head

    self.size -= 1
    data
  end

  def shuffle
    deque = deep_clone
    i = size - 1
    while i >= 0
      deque.swap!(i, rand(size))
      i -= 1
    end
    deque
  end

  def shuffle!
    i = size - 1
    while i >= 0
      swap!(i, rand(size))
      i -= 1
    end
    self
  end

  def slice(beg_idx, n_idcs)
    result = Deque.new

    node = node_at(beg_idx)
    return unless node

    i = 0
    loop do
      break if i == n_idcs
      result.push(node.data)
      return result unless node.succ
      node = node.succ
      i += 1
    end
    result
  end

  def sort
    return self if size == 1

    mid = size / 2
    left = slice(0, mid)
    right = slice(mid, mid + 1)

    left = left.sort
    right = right.sort

    merge_halves(left, right)
  end

  def sort_by(&block)
    return self if size == 1

    mid = size / 2
    left = slice(0, mid)
    right = slice(mid, mid + 1)

    left = left.sort_by(&block)
    right = right.sort_by(&block)

    merge_by(left, right, &block)
  end

  def sum
    s = 0
    each do |e|
      s += e
    end
    s
  end

  def swap!(idx, jdx)
    node_swap(
      node_at(idx),
      node_at(jdx)
    )
  end

  def take(num)
    slice(0, num)
  end

  def to_a
    arr = []
    each { |e| arr.push(e) }
    arr
  end

  def to_h
    hash = {}
    i = 0
    node = head
    while i < size
      if ![Deque, Array].include?(node.data.class)
        raise TypeError.new("wrong element type #{node.data.class} at #{i} (expected deque or array)")
      elsif node.data.size != 2
        raise ArgumentError.new("wrong deque size at #{i} (expected 2, was #{node.data.size})")
      end
      hash[node.data[0]] = node.data[1]
      node = node.succ
      i += 1
    end
    hash
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

  def transpose
    result = Deque.new
    column_idx = 0
    row_size = head.data.size
    while column_idx < head.data.size
      if self[column_idx].size != row_size
        raise IndexError.new(
          "element size differs " \
          "(#{self[column_idx].size} should be #{row_size})"
        )
      end
      row_idx = 0
      row = Deque.new
      while row_idx < size
        row.push(self[row_idx][column_idx])
        row_idx += 1
      end
      result.push(row)
      column_idx += 1
    end
    result
  end

  def union(*deques)
    result = Deque.new
    each do |e|
      result.push(e) unless result.include?(e)
    end
    deques.each do |deque|
      deque.each do |e|
        result.push(e) unless result.include?(e)
      end
    end
    result
  end

  def uniq
    deque = Deque.new
    each do |e|
      deque.push(e) unless deque.include?(e)
    end
    deque
  end

  def uniq!
    each_node do |node|
      remove(node) unless one? { |e| e == node.data }
    end
  end

  def unshift(element)
    node = Node.new(element, succ: head)
    head.pred = node if head
    self.head = node
    self.tail = node unless tail

    self.size += 1
    self
  end

  def values_at(*indeces)
    result = Deque.new
    indeces.each do |idx|
      result << self[idx]
    end
    result
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

  def -(list)
    reject { |e| list.include?(e) }
  end

  def *(int)
    raise ArgumentError.new("negative argument") if int < 0
    deque = Deque.new
    return deque if int == 0
    i = 0
    until i == int
      each { |e| deque.push(e) }
      i += 1
    end
    deque
  end

  protected

  attr_accessor :head

  private

  attr_accessor :tail
  attr_writer :size

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

  def index_range(range)
    slice(range.begin, range.size)
  end

  def merge_by(left, right, &block)
    node = left.head
    other_node = right.head
    result = Deque.new
    while node && other_node
      case block.call(node.data, other_node.data)
      when -1
        result << node.data
        node = node.succ
      when 0
        result << node.data
        result << other_node.data
        node = node.succ
        other_node = other_node.succ
      when 1
        result << other_node.data
        other_node = other_node.succ
      end
    end

    if node
      while node
        result << node.data
        node = node.succ
      end
    else
      while other_node
        result << other_node.data
        other_node = other_node.succ
      end
    end

    result
  end

  def merge_halves(left, right)
    node = left.head
    other_node = right.head
    result = Deque.new
    while node && other_node
      if node.data < other_node.data
        result << node.data
        node = node.succ
      else
        result << other_node.data
        other_node = other_node.succ
      end
    end

    if node
      while node
        result << node.data
        node = node.succ
      end
    else
      while other_node
        result << other_node.data
        other_node = other_node.succ
      end
    end

    result
  end

  def negative_idx(idx, count = -1, node = tail)
    return node.data if count == idx
    return unless node.pred

    negative_idx(idx, count - 1, node.pred)
  end

  def nindex(node, count = 0, cnode = head)
    return nil unless cnode
    return count if node == cnode
    nindex(node, count + 1, cnode.succ)
  end

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

  def reverse_each_node(&block)
    node = tail
    while node
      block.call(node)
      node = node.pred
    end
    self
  end

  def node_swap(node, other)
    if nindex(node) < nindex(other)
      n_pred = node.pred
      n_succ = node.succ
      o_pred = other.pred
      o_succ = other.succ
      if n_pred
        n_pred.succ = other
      else
        self.head = other
      end

      if o_succ
        o_succ.pred = node
      else
        self.tail = node
      end

      if node.adjacent?(other)
        node.pred = other
        other.succ = node
      else
        node.pred = o_pred
        other.succ = n_succ
        n_succ.pred = other
        o_pred.succ = node
      end

      node.succ = o_succ
      other.pred = n_pred
      self
    elsif node == other
      self
    else
      node_swap(other, node)
    end
  end

  class Node
    attr_accessor :data, :pred, :succ

    def initialize(data, pred: nil, succ: nil)
      @data = data
      @pred = pred
      @succ = succ
    end

    def adjacent?(node)
      (succ == node && node.pred == self) ||
      (pred == node && node.succ == self)
    end

    def append(element)
      self.succ = Node.new(element, pred: self, succ: succ)
    end

    def to_s
      return data.inspect if data

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

p Deque.new(0..9).values_at(1, 3, 5)

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

# deque[-1] = 8
# p deque
# p deque + Deque(7)
# p deque
# p list
# p deque == list
# p deque.size

# deque = Deque.new(9, 8, 7, 6, 5, 4, 3, 2, 1)
#
# p deque.sort
# p deque

# class Array
#   def product(*args)
#     if args.size == 1
#       result = []
#       each do |e|
#         args[0].each do |f|
#           result << [e, f]
#         end
#       end
#       result
#     else
#       temp = args[0].product(*args[1..-1])
#       result = []
#       each do |e|
#         temp.each do |f|
#           result << ([e] + f)
#         end
#       end
#       result
#     end
#   end
# end
#
# [1, 2, 3].product(['a', 'b'], [:c, :d], [4, 5, 6]).each do |e|
#   p e
# end

# Deque.new(1, 2, 3).product(Deque.new('a', 'b'), Deque.new(:c, :d), Deque.new(4, 5, 6)).each do |e|
#   p e
# end

# i = 0
# key = :a
# while i <= 5_000_000
#   deque << [key, i]
#   key = key.succ
#   i += 1
# end
#
# puts Benchmark.measure {
#   deque.to_h
# }

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
