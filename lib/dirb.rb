require 'rubygems'
require 'tempfile'
require 'open3'
require 'erb'
module Dirb
  class Diff
    class << self
      attr_writer :default_format
      def default_format
        @default_format || :text
      end
    end
    include Enumerable
    attr_reader :string1, :string2, :diff_options, :diff
    def initialize(string1, string2, diff_options = "-U 10000")
      @string1, @string2 = string1, string2
      @diff_options = diff_options
    end

    def diff
      @diff ||= Open3.popen3(
        *[diff_bin, diff_options, tempfile(string1), tempfile(string2)]
      ) { |i, o, e| o.read }
      @diff = @string1.gsub(/^/, " ") if @diff =~ /\A\s*\Z/
      @diff
    end

    def each
      lines = diff.split("\n").reject{|x| x =~ /^---|\+\+\+|@@/ }.
        map{|line| line + "\n"}
      if block_given?
        lines.each{|line| yield line}
      else
        Enumerable::Enumerator.new(lines)
      end
    end

    def each_chunk
      old_state = nil
      chunks = inject([]) do |cc, line|
        state = line.each_char.first
        if state == old_state
          cc.last << line
        else
          cc.push line.dup
        end
        old_state = state
        cc
      end

      if block_given?
        chunks.each{|chunk| yield chunk }
      else
        Enumerable::Enumerator.new(chunks)
      end
    end

    def tempfile(string)
      t = Tempfile.new('dirb')
      t.print(string)
      t.flush
      t.path
    end

    def to_s(format = nil)
      format ||= self.class.default_format
      formats = Format.instance_methods(false).map{|x| x.to_s}
      if formats.include? format.to_s
        enum = self
        enum.extend Format
        enum.send format
      else
        raise ArgumentError,
          "Format #{format.inspect} not found in #{formats.inspect}"
      end
    end
    private

    def diff_bin
      bin = `which diff`.chomp
      if bin.empty?
        raise "Can't find a diff executable in PATH #{ENV['PATH']}"
      end
      bin
    end

    module Format
      def color
        map do |line|
          case line
          when /^\+/
            "\033[32m#{line.chomp}\033[0m"
          when /^-/
            "\033[31m#{line.chomp}\033[0m"
          else
            line.chomp
          end
        end.join("\n") + "\n"
      end

      def text
        to_a.join
      end

      def html
        HtmlFormatter.new(self).to_s
      end

      def html_with_inline_highlights
        HtmlFormatter.new(self, :highlight_words => true).to_s
      end
    end

    class HtmlFormatter
      def initialize(diff, options = {})
        @diff = diff
        @options = options
      end

      def to_s
        if @options[:highlight_words]
          wrap_lines(highlighted_words)
        else
          wrap_lines(@diff.map{|line| wrap_line(ERB::Util.h(line))})
        end
      end

      private
      def wrap_line(line)
        cleaned = line.gsub(/^./, '').chomp
        case line
        when /^\+/
          '    <li class="ins"><ins>' + cleaned + '</ins></li>'
        when /^-/
          '    <li class="del"><del>' + cleaned + '</del></li>'
        when /^ /
          '    <li class="unchanged"><span>' + cleaned + '</span></li>'
        end
      end

      def wrap_lines(lines)
        %'<div class="diff">\n  <ul>\n#{lines.join("\n")}\n  </ul>\n</div>\n'
      end

      def highlighted_words
        chunks = @diff.each_chunk.to_a
        processed = []
        lines = chunks.each_with_index.map do |chunk1, index|
          next if processed.include? index
          processed << index
          chunk1 = chunk1
          chunk2 = chunks[index + 1]
          if not chunk2
            next chunk1
          end

          chunk1 = ERB::Util.h(chunk1)
          chunk2 = ERB::Util.h(chunk2)

          dir1 = chunk1.each_char.first
          dir2 = chunk2.each_char.first
          case [dir1, dir2]
          when ['-', '+']
            line_diff = Dirb::Diff.new(
              split_characters(chunk1),
              split_characters(chunk2)
            )
            hi1 = reconstruct_characters(line_diff, '-')
            hi2 = reconstruct_characters(line_diff, '+')
            processed << (index + 1)
            [hi1, hi2]
          else
            chunk1
          end
        end.flatten.compact
        lines.map{|line| line.each_line.map(&:chomp).to_a if line }.flatten.compact.
          map{|line|wrap_line(line) }.compact
      end

      def split_characters(chunk)
        chunk.gsub(/^./, '').each_line.map do |line|
          line.chomp.split('') + ['\n']
        end.flatten.join("\n")
      end

      def reconstruct_characters(line_diff, type)
        line_diff.each_chunk.map do |l|
          re = /(^|\\n)#{Regexp.escape(type)}/
          case l
          when re
            "<strong>" + l.gsub(re, '').gsub("\n", '').
              gsub('\n', "</strong>\n<strong>") + "</strong>"
          when /^ /
            l.gsub(/^./, '').gsub("\n", '').
              gsub('\r', "\r").gsub('\n', "\n")
          end
        end.join('').split("\n").map do |l|
          type + l
        end
      end
    end
  end
end
