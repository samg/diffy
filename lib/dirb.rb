require 'rubygems'
require 'tempfile'
require 'open3'
module Dirb
  class Diff
    include Enumerable
    attr_reader :string1, :string2
    def initialize(string1, string2)
      @string1, @string2 = string1, string2
    end

    def diff
      @diff ||= Open3.popen3(
        *['diff', '-U 1000', tempfile(string1), tempfile(string2)]
      ) { |i, o, e| o.read }
      @diff = @string1.gsub(/^/, " ") if @diff =~ /\A\s*\Z/
      @diff
    end

    def each &block
      diff.each_line.reject{|x| x =~ /^---|\+\+\+|@@/ }.each &block
    end

    def tempfile(string)
      t = Tempfile.new('dirb')
      t.print(string)
      t.flush
      t.path
    end

    def to_s
      to_a.join
    end

    def to_html
      lines = map do |line|
        case line
        when /^\+/
          '  <li class="ins"><ins>' + line.gsub(/^./, '').chomp + '</ins></li>'
        when /^-/
          '  <li class="del"><del>' + line.gsub(/^./, '').chomp + '</del></li>'
        when /^ /
          '  <li class="unchanged"><span>' + line.gsub(/^./, '').chomp + '</span></li>'
        end
      end

      %'<ul class="diff">\n#{lines.join("\n")}\n</ul>\n'
    end
  end
end
