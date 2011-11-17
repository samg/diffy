module Diffy
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
      when /^(---|\+\+\+|\\\\)/
        '    <li class="diff-comment"><span>' + line.chomp + '</span></li>'
      when /^\+/
        '    <li class="ins"><ins>' + cleaned + '</ins></li>'
      when /^-/
        '    <li class="del"><del>' + cleaned + '</del></li>'
      when /^ /
        '    <li class="unchanged"><span>' + cleaned + '</span></li>'
      when /^@@/
        '    <li class="diff-block-info"><span>' + line.chomp + '</span></li>'
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
          next ERB::Util.h(chunk1)
        end

        dir1 = chunk1.each_char.first
        dir2 = chunk2.each_char.first
        case [dir1, dir2]
        when ['-', '+']
          line_diff = Diffy::Diff.new(
            split_characters(chunk1),
            split_characters(chunk2)
          )
          hi1 = reconstruct_characters(line_diff, '-')
          hi2 = reconstruct_characters(line_diff, '+')
          processed << (index + 1)
          [hi1, hi2]
        else
          ERB::Util.h(chunk1)
        end
      end.flatten
      lines.map{|line| line.each_line.map(&:chomp).to_a if line }.flatten.compact.
        map{|line|wrap_line(line) }.compact
    end

    def split_characters(chunk)
      chunk.gsub(/^./, '').each_line.map do |line|
        (line.chomp.split('') + ['\n']).map{|chr| ERB::Util.h(chr) }
      end.flatten.join("\n") + "\n"
    end

    def reconstruct_characters(line_diff, type)
      enum = line_diff.each_chunk
      enum.each_with_index.map do |l, i|
        re = /(^|\\n)#{Regexp.escape(type)}/
        case l
        when re
          highlight(l)
        when /^ /
          if i > 1 and enum.to_a[i+1] and l.each_line.to_a.size < 4
            highlight(l)
          else
            l.gsub(/^./, '').gsub("\n", '').
              gsub('\r', "\r").gsub('\n', "\n")
          end
        end
      end.join('').split("\n").map do |l|
        type + l.gsub('</strong><strong>' , '')
      end
    end

    def highlight(lines)
      "<strong>" + lines.gsub(/(^|\\n)./, '').gsub("\n", '').
        gsub('\n', "</strong>\n<strong>") + "</strong>"
    end
  end
end
