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
        lines = @diff.each_chunk.each_cons(2).map do |(chunk1, chunk2)|
          dir1 = chunk1.each_char.first
          dir2 = chunk2.each_char.first
          case [dir1, dir2]
          when ['-', '+']
            word_diff = Dirb::Diff.new(
              words_from(chunk1),
              words_from(chunk2)
            )
            hi1 = dir1 + word_diff.each_chunk.map do |l|
              l.chomp!
              case l
              when /^-/
                "<em>" + l.gsub(/^-/, '') + "</em>"
              when /^ /
                l.gsub(/^./, '')
              end
            end.compact.join(' ').gsub(/\n/, ' ')
            hi2 = dir2 + word_diff.each_chunk.map do |l|
              l.chomp!
              case l
              when /^\+/
                "<em>" + l.gsub(/^\+/, '') + "</em>"
              when /^ /
                l.gsub(/^./, '')
              end
            end.compact.join(' ').gsub(/\n/, ' ')
            [hi1, hi2]
          end
        end.flatten
        lines.map{|x| wrap_line(x) }
      end

      def words_from(line)
        ERB::Util.h(line.sub(/./, '').split(' ').join("\n"))
      end
    end
  end
end
