module Diffy
  class Diff
    class << self
      attr_writer :default_format
      def default_format
        @default_format || :text
      end
    end
    include Enumerable
    attr_reader :string1, :string2, :options, :diff

    # supported options
    # +:diff+::    A cli options string passed to diff
    # +:source+::  Either _strings_ or _files_.  Determines whether string1
    #              and string2 should be interpreted as strings or file paths.
    def initialize(string1, string2, options = {})
      @options = {:diff => '-U 10000', :source => 'strings', :include_diff_info => false}.merge(options)
      if ! ['strings', 'files'].include?(@options[:source])
        raise ArgumentError, "Invalid :source option #{@options[:source].inspect}. Supported options are 'strings' and 'files'."
      end
      @string1, @string2 = string1, string2
    end

    def diff
      @diff ||= begin
        paths = case options[:source]
          when 'strings'
            [tempfile(string1), tempfile(string2)]
          when 'files'
            [string1, string2]
          end
        diff_opts = options[:diff].is_a?(Array) ? options[:diff] : [options[:diff]]
        diff = Open3.popen3(diff_bin, *(diff_opts + paths)) { |i, o, e| o.read }
        if diff =~ /\A\s*\Z/
          diff = case options[:source]
          when 'strings' then string1
          when 'files' then File.read(string1)
          end.gsub(/^/, " ")
        end
        diff
      end
    end

    def each
      puts @options[:include_diff_info].to_s
      lines = case @options[:include_diff_info]
      when false then diff.split("\n").reject{|x| x =~ /^(---|\+\+\+|@@|\\\\)/ }.map {|line| line + "\n" }
      when true then diff.split("\n").map {|line| line + "\n" }
      end
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
      t = Tempfile.new('diffy')
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

  end
end
