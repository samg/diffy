module Diffy
  class Diff
    ORIGINAL_DEFAULT_OPTIONS = {
      :source => 'strings',
      :include_diff_info => false,
      :include_plus_and_minus_in_html => false,
      :context => 10_000,
      :allow_empty_diff => true,
      :rugged => {},
    }

    class << self
      attr_writer :default_format
      def default_format
        @default_format ||= :text
      end

      # default options passed to new Diff objects
      attr_writer :default_options
      def default_options
        @default_options ||= ORIGINAL_DEFAULT_OPTIONS.dup
      end

    end
    include Enumerable
    attr_reader :string1, :string2, :options

    # supported options
    # +:diff+::    A cli options string passed to diff
    # +:source+::  Either _strings_ or _files_.  Determines whether string1
    #              and string2 should be interpreted as strings or file paths.
    # +:include_diff_info+::    Include diff header info
    # +:include_plus_and_minus_in_html+::    Show the +, -, ' ' at the
    #                                        beginning of lines in html output.
    def initialize(string1, string2, options = {})
      @options = self.class.default_options.merge(options)
      if ! ['strings', 'files'].include?(@options[:source])
        raise ArgumentError, "Invalid :source option #{@options[:source].inspect}. Supported options are 'strings' and 'files'."
      end
      @options[:rugged][:context_lines] = @options[:context] if @options[:rugged][:context_lines].nil?
      @string1, @string2 = string1, string2
      @diff_empty = false
    end

    def diff
      @diff ||= begin
        case options[:source]
          when 'strings'
            diff = Rugged::Patch.from_strings(string1, string2, **options[:rugged]).to_s
          when 'files'
            diff = Rugged::Patch.from_strings(File.read(string1), File.read(string2), **options[:rugged]).to_s
          end

        diff.force_encoding('ASCII-8BIT') if diff.respond_to?(:valid_encoding?) && !diff.valid_encoding?
        if diff =~ /\A\s*\Z/ && !options[:allow_empty_diff]
          @diff_empty = true
          diff = case options[:source]
          when 'strings' then string1
          when 'files' then File.read(string1)
          end.gsub(/^/, " ")
        end
        diff
      end
    end

    def each
      lines = case @options[:include_diff_info]
      when false
        # this "primes" the diff and sets up the paths we'll reference below.
        diff

        # diff --git a/file b/file
        # index 71779d2..d5f7fc3 100644 
        # --- test/file
        # +++ b/file
        # @@ -1 +1 @@
        diff.split("\n").drop(@diff_empty ? 0 : 5).map {|line| line + "\n" }

      when true
        diff.split("\n").map {|line| line + "\n" }
      end

      if block_given?
        lines.each{|line| yield line}
      else
        lines.to_enum
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
        chunks.to_enum
      end
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
  end
end
