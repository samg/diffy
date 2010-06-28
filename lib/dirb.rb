require 'rubygems'
require 'diff/lcs'
require 'set'
module Dirb
  class Diff
    include Enumerable
    attr_reader :string1, :string2, :seperator
    def initialize(string1, string2, seperator="\n")
      @string1, @string2, @seperator = string1, string2, seperator
    end

    def diff
      @diff ||= ::Diff::LCS.diff(split(@string1), split(@string2))
    end

    def each
      seen = Set[]
      longer = [split(@string1), split(@string2)].sort_by(&:size).last
      longer.each_with_index do |item, index|
        if changes = diff.detect{|changes| changes.any?{|x| x.position == index}}
          changes.sort_by do |x|
            "#{x.action=='+' ? 1 : 0}#{x.position}"
          end.each do |change|
            next if seen.include?(change)
            seen.add(change)
            yield "#{change.action}#{change.element}"
          end
        else
          yield " #{item}"
        end
      end
    end

    def to_s
      map{|x| x.to_s}.join(seperator) + seperator
    end

    def split(string)
      string.split(seperator)
    end
  end
end
