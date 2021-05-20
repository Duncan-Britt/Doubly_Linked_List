# Doubly_Linked_List
Implementation of Double Ended Queue (Deque) as Doubly Linked List in Ruby
This project was done for educational/entertainment purposes.

Most Deque methods exist for Ruby's Array class by the same name, and can be
used in the same or a similar manner.

Class Methods:

new
  Deque.new                          => ()
  Deque.new(1, 'a', :g)              => (1 <> "a" <> :g)
  Deque.new(1..9)                    => (1 <> 2 <> 3 <> 4 <> 5 <> 6 <> 7 <> 8 <> 9)
  Deque.new('a', 'b', 'c', rep: 2)   => ("a" <> "b" <> "c" <> "a" <> "b" <> "c")



Instance Methods:

all?(&block)
  Passes each element of the collection to the given block. The method returns true if the block never returns false or nil. If the block is not given, Ruby adds an implicit block of { |obj| obj } which will cause all? to return true when none of the collection members are false or nil.

  Deque.new(1..9).all? { |e| e.class == Integer }   => true
  Deque.new(1, 7, 3, 4).all? { |e| e.odd? }         => false
  Deque.new(true, nil, 3).all?                      => false
