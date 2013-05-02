#!/usr/bin/env ruby

require 'promise'

class LazyStream
  def initialize(first=nil, &rest)
    @first = first
    @rest = block_given? ? promise(&rest) : promise { LazyStream.new }
  end

  attr_reader :first, :rest

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

  def drop(n)
    empty? || n < 1 ? self : rest.drop(n - 1)
  end

  def each(&proc)
    unless empty?
      proc.call(first)
      rest.each(&proc)
    end
  end

  def map(&proc)
    empty? ? self : LazyStream.new(proc.call(first)) { rest.map(&proc) }
  end

  def reduce(initial=0, &proc)
    empty? ? initial : rest.reduce(proc.call(initial, first), &proc)
  end

  def select(&pred)
    if empty?
      self
    elsif pred.call(first)
      LazyStream.new(first) { rest.select(&pred) }
    else
      rest.select(&pred)
    end
  end

  def take(n)
    empty? || n < 1 ? LazyStream.new :
                      LazyStream.new(first) { rest.take(n - 1) }
  end

  def to_a
    reduce([]) { |a, x| a << x }
  end

  def print
    each { |x| puts x }
  end

  def scale(factor)
    map { |x| x * factor }
  end

  def partial_sums(initial=0)
    partial_sum = initial + first
    LazyStream.new(partial_sum) { rest.partial_sums(partial_sum) }
  end

  def map_successive_pairs(&proc)
    if empty? || rest.empty?
      LazyStream.new
    else
      LazyStream.new(proc.call(first, rest.first)) do
        rest.rest.map_successive_pairs(&proc)
      end
    end
  end

  def self.map(*streams, &proc)
    if streams.first.empty?
      LazyStream.new
    else
      LazyStream.new(proc.call(*streams.map(&:first))) do
        map(*streams.map(&:rest), &proc)
      end
    end
  end

  def self.add(*streams)
    map(*streams) { |*args| args.reduce(&:+) }
  end

  def self.interleave(s1, s2)
    s1.empty? ? s2 : LazyStream.new(s1.first) { interleave(s2, s1.rest) }
  end
end

module Kernel
  def lazy_stream(first=nil, &rest)
    LazyStream.new(first, &rest)
  end
end
