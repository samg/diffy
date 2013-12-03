module Diffy
  class Diff3 < Diffy::Diff
    class << self
      attr_writer :default_format
      def default_format
        @default_format || :text
      end

      attr_writer :default_options
      # default options passed to new Diff objects
      def default_options
        @default_options ||= {
            :diff3 => ['-m', '-L older', '-L mine', '-L yours'],
            :line_merge => true # tries to intelligently merge three way conflicts using line by line comparisons
        }
      end

      def diff_bin
        @bin ||= begin
          if WINDOWS
            bin = `which diff3.exe`.chomp
          else
            bin = `which diff3`.chomp
          end

          raise "Can't find a diff3 executable in PATH #{ENV['PATH']}" if bin.empty?
          bin
        end
      end
    end

    attr_reader :string3

    def initialize(string1, string2, string3, options = {})
      @options = Diffy::Diff.default_options.merge(self.class.default_options.merge(options))
      if ! ['strings', 'files'].include?(@options[:source])
        raise ArgumentError, "Invalid :source option #{@options[:source].inspect}. Supported options are 'strings' and 'files'."
      end

      @string1, @string2, @string3 = ensure_line_breaks(string1, string2, string3)
    end

    def older
      string1
    end

    def yours
      string2
    end

    def mine
      string3
    end

    def diff3
      @diff3 ||= begin
        paths = case options[:source]
                  when 'strings'
                    [tempfile(older), tempfile(yours), tempfile(mine)]
                  when 'files'
                    [string1, string2, string3]
                end

        exec(paths)
      end
    end

    def three_way_conflicts?
      change_groups.any? {|g| g.three_way_conflict?}
    end

    def conflicts?
      change_groups.any? {|g| g.conflicts?}
    end

    def change_groups
      @change_groups ||= begin
        groups = []
        current = nil

        diff3.lines.each do |line|
          if line.start_with?('<<<<<<<')
            if current
              current.close
              groups << current
            end
            current = ChangeGroup.new(self)
            current.add_line(line)
          elsif current and current.open?
            current.add_line(line)
          else
            groups << current if current
            current = ChangeGroup.new(self)
            current.add_line(line)
          end
        end

        if current
          current.close
          groups << current
        end

        groups
      end
    end

    class ChangeGroup

      attr_reader :older, :mine, :yours

      def initialize(diff)
        @diff = diff
        @open = true
        @older = []
        @yours = []
        @mine = []
        @target = @older
        @three_way_conflict = false
      end

      def conflicts?
        @yours.any? or @mine.any?
      end

      def open?
        @open
      end

      def close
        @open = false
      end

      def three_way_conflict?
        @three_way_conflict
      end

      def add_line(line)
        if line.start_with?('<<<<<<<')
          if line.include?('older')
            @three_way_conflict = true
          else
            @target = @yours
          end
        elsif line.start_with?('|||||||')
          @target = @yours
        elsif line.start_with?('=======')
          @target = @mine
        elsif line.start_with?('>>>>>>>')
          @open = false
          # if there was a 2 way conflict than the older will always be the same content as mine
          @older = @mine unless @three_way_conflict
        else
          @target << line
        end
      end

      def patched_mine
        if conflicts?
          if mine.any? and mine != older
            # only try our own line per line merge strategy if the line counts are the same.
            if @diff.options[:line_merge] and mine.length == older.length
              lines = []
              mine.each_with_index do |line, index|
                lines << (older[index] == line ? yours[index] : line)
              end
              lines
            else
              mine
            end
          else
            yours
          end
        else
          older
        end
      end
    end

    # attempts to update mine to include newly added, non-conflicted changes from yours
    def patched_mine
      @patched_mine ||= begin
        lines = []
        change_groups.each do |group|
          lines += group.patched_mine
        end
        lines.join('')
      end
    end

    def diff
      @diff ||= Diffy::Diff.new(yours, patched_mine).diff
    end

    protected

    # options pass to diff program
    def diff_options
      Array(options[:diff3])
    end

    # make sure the strings all end with a line break
    def ensure_line_breaks(*strings)
      strings.map do |str|
        str.end_with?("\n") ? str : str + "\n"
      end
    end
  end


end