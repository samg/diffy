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
          "<ins>" + line.gsub(/^./, '').strip + "</ins>"
        when /^-/
          "<del>" + line.gsub(/^./, '').strip + "</del>"
        when /^ /
          line.gsub(/^-/, '').strip
        end
      end

      %'<ul class="diff">\n  <li>#{lines.join("</li>\n  <li>")}</li>\n</ul>\n'
    end
  end
end
