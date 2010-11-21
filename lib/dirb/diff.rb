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
      lines = diff.split("\n").reject{|x| x =~ /^---|\+\+\+|@@|\\\\/ }.
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

  end
end
