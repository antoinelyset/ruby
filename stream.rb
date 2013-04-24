#!/usr/bin/env ruby

def memo_proc(&proc)
  already_run = false
  result = nil
  lambda do
    if already_run
      result
    else
      result = proc.call
      already_run = true
      result
    end
  end
end

class Stream
  def initialize(first=nil, &rest)
    @first = first
    @rest = block_given? ? memo_proc(&rest) : lambda {}
  end

  attr_reader :first

  def rest
    @rest.call
  end

  def empty?
    first.nil?
  end

  def at(n)
    if empty?
      nil
    elsif n == 0
      first
    else
      rest.at(n - 1)
    end
  end

  def display
    each { |x| puts x }
  end

  def drop(n)
    if empty? or n < 1
      self
    else
      rest.drop(n - 1)
    end
  end

  def each(&proc)
    unless empty?
      proc.call(first)
      rest.each(&proc)
    end
  end

  def map(&proc)
    if empty?
      self
    else
      Stream.new(proc.call(first)) { rest.map(&proc) }
    end
  end

  def reduce(initial=0, &proc)
    if empty?
      initial
    else
      rest.reduce(proc.call(initial, first), &proc)
    end
  end

  def select(&pred)
    if empty?
      self
    elsif pred.call(first)
      Stream.new(first) { rest.select(&pred) }
    else
      rest.select(&pred)
    end
  end

  def take(n)
    if empty? or n < 1
      Stream.new
    else
      Stream.new(first) { rest.take(n - 1) }
    end
  end

  def scale(factor)
    map { |x| x * factor }
  end

  def partial_sums(initial=0)
    partial_sum = initial + first
    Stream.new(partial_sum) { rest.partial_sums(partial_sum) }
  end

  def self.map(*streams, &proc)
    if streams.first.empty?
      Stream.new
    else
      Stream.new(proc.call(*streams.map(&:first))) do
        map(*streams.map(&:rest), &proc)
      end
    end
  end

  def self.add(*streams)
    map(*streams) { |*args| args.reduce(&:+) }
  end

  def self.interleave(s1, s2)
    if s1.empty?
      s2
    else
      Stream.new(s1.first) { interleave(s2, s1.rest) }
    end
  end
end
