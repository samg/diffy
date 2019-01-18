require 'rspec'

describe Diffy::Diff do
  describe 'diffing two files' do
    def tempfile(string, filename = 'diffy-spec')
      t = Tempfile.new(filename)
      # ensure tempfiles aren't unlinked when GC runs by maintaining a
      # reference to them.
      tempfiles ||= []
      tempfiles.push(t)
      t.print(string)
      t.flush
      t.close
      t.path
    end

    it 'accept file paths as arguments' do
      string1 = "foo\nbar\nbang\n"
      string2 = "foo\nbang\n"
      path1 = tempfile(string1)
      path2 = tempfile(string2)
      expect(described_class.new(path1, path2, source: 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
      DIFF
    end

    it 'accept file paths with spaces as arguments' do
      string1 = "foo\nbar\nbang\n"
      string2 = "foo\nbang\n"
      path1 = tempfile(string1, 'path with spaces')
      path2 = tempfile(string2, 'path with spaces')
      expect(described_class.new(path1, path2, source: 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
      DIFF
    end

    it 'accept file paths with spaces as arguments on windows' do
      begin
        orig_verbose = $VERBOSE
        $VERBOSE = nil # silence redefine constant warnings
        orig_windows = Diffy::WINDOWS
        described_class::WINDOWS = true
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        path1 = tempfile(string1, 'path with spaces')
        path2 = tempfile(string2, 'path with spaces')
        expect(described_class.new(path1, path2, source: 'files').to_s).to eq <<-DIFF
 foo
-bar
 bang
        DIFF
      ensure
        described_class::WINDOWS = orig_windows
        $VERBOSE = orig_verbose
      end
    end

    describe 'with no line different' do
      it 'show everything' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbar\nbang\n"
        path1 = tempfile(string1)
        path2 = tempfile(string2)
        expect(described_class.new(path1, path2, source: 'files', allow_empty_diff: false)
          .to_s).to eq <<-DIFF
 foo
 bar
 bang
          DIFF
      end

      it 'not show everything if the :allow_empty_diff option is set' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbar\nbang\n"
        path1 = tempfile(string1)
        path2 = tempfile(string2)
        expect(described_class.new(path1, path2, source: 'files', allow_empty_diff: true).to_s).to eq('')
      end
    end

    describe 'with lines that start with backslashes' do
      it 'not leave lines out' do
        string1 = "foo\n\\\\bag\nbang\n"
        string2 = "foo\n\\\\bar\nbang\n"
        path1 = tempfile(string1)
        path2 = tempfile(string2)
        expect(described_class.new(path1, path2, source: 'files').to_s).to eq <<-DIFF
 foo
-\\\\bag
+\\\\bar
 bang
        DIFF
      end
    end

    describe 'with non valid UTF bytes' do
      it 'not raise invalid encoding issues' do
        string1 = "Foo ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000\n"
        string2 = "Bar ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000\n"
        path1 = tempfile(string1)
        path2 = tempfile(string2)
        desired = <<-DIFF
-Foo ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000
+Bar ICS95095010000000000083320000BS01030000004100+\xFF00000000000000000
        DIFF
        desired.force_encoding('ASCII-8BIT') if desired.respond_to?(:force_encoding)
        expect(described_class.new(path1, path2, source: 'files').to_s).to eq(desired)
      end
    end
  end

  describe 'handling temp files' do
    it 'unlink tempfiles after generating the diff' do
      before_tmpfiles = Dir.entries(Dir.tmpdir)
      described_class.new('a', 'b').to_s
      after_tmpfiles = Dir.entries(Dir.tmpdir)
      expect(before_tmpfiles).to match_array(after_tmpfiles)
    end

    it 'still be able to generate multiple diffs string' do
      d = described_class.new('a', 'b')
      expect(d.to_s).to be_a String
    end

    it 'still be able to generate multiple diffs html' do
      d = described_class.new('a', 'b')
      expect(d.to_s(:html)).to be_a String
    end
  end

  describe 'options[:context]' do
    it 'limit context lines to 1' do
      diff = described_class.new("foo\nfoo\nBAR\nbang\nbaz", "foo\nfoo\nbar\nbang\nbaz", context: 1)
      expect(diff.to_s).to eq <<-DIFF
 foo
-BAR
+bar
 bang
      DIFF
    end
  end

  describe 'options[:include_plus_and_minus_in_html]' do
    it 'defaults to false' do
      diffy = described_class.new(" foo\nbar\n", "foo\nbar\n")
      expect(diffy.options[:include_plus_and_minus_in_html]).to eq(false)
    end

    it 'can be set to true' do
      diffy = described_class.new(" foo\nbar\n", "foo\nbar\n", include_plus_and_minus_in_html: true)
      expect(diffy.options[:include_plus_and_minus_in_html]).to eq(true)
    end

    describe 'formats' do
      it 'includes symbols in html_simple' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_plus_and_minus_in_html: true)
                                .to_s(:html_simple)
        expect(output).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span><span class="symbol"> </span>foo</span></li>
    <li class="del"><del><span class="symbol">-</span>bar</del></li>
    <li class="unchanged"><span><span class="symbol"> </span>bang</span></li>
  </ul>
</div>
        HTML
      end

      it 'includes symbols in html' do
        output = described_class.new("foo\nbar\nbang\n", "foo\naba\nbang\n", include_plus_and_minus_in_html: true)
                                .to_s(:html)
        expect(output).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span><span class="symbol"> </span>foo</span></li>
    <li class="del"><del><span class="symbol">-</span>ba<strong>r</strong></del></li>
    <li class="ins"><ins><span class="symbol">+</span><strong>a</strong>ba</ins></li>
    <li class="unchanged"><span><span class="symbol"> </span>bang</span></li>
  </ul>
</div>
        HTML
      end
    end
  end

  describe 'options[:include_diff_info]' do
    it 'defaults to false' do
      diffy = described_class.new(" foo\nbar\n", "foo\nbar\n")
      expect(diffy.options[:include_diff_info]).to eq(false)
    end

    it 'can be set to true' do
      diffy = described_class.new(" foo\nbar\n", "foo\nbar\n", include_diff_info: true)
      expect(diffy.options[:include_diff_info]).to eq(true)
    end

    it 'includes all diff output at' do
      output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s
      expect(output.to_s).to match(/@@/)
    end

    it 'includes all diff output dash' do
      output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s
      expect(output).to match(/---/)
    end

    it 'includes all diff output plus' do
      output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s
      expect(output).to match(/\+\+\+/)
    end

    describe 'formats' do
      it 'works for :color one' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:color)
        expect(output).to match(/\e\[0m\n\e\[36m\@\@/)
      end

      it 'works for :color two' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:color)
        expect(output.to_s).to match(/\e\[90m---/)
      end

      it 'works for :color three' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:color)
        expect(output.to_s).to match(/\e\[0m\n\e\[90m\+\+\+/)
      end

      it 'works for :html_simple class' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:html_simple)
        expect(output.split("\n")).to include('    <li class="diff-block-info"><span>@@ -1,3 +1,2 @@</span></li>')
      end

      it 'works for :html_simple plus' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:html_simple)
        expect(output).to include('<li class="diff-comment"><span>+++')
      end

      it 'works for :html_simple dash' do
        output = described_class.new("foo\nbar\nbang\n", "foo\nbang\n", include_diff_info: true).to_s(:html_simple)
        expect(output).to include('<li class="diff-comment"><span>---')
      end
    end
  end

  describe 'options[:diff]' do
    it 'accept an option to diff' do
      diff = described_class.new(" foo\nbar\n", "foo\nbar\n", diff: '-w', allow_empty_diff: false)
      expect(diff.to_s).to eq <<-DIFF
  foo
 bar
      DIFF
    end

    it 'accept multiple arguments to diff' do
      diff = described_class.new(" foo\nbar\n", "foo\nbaz\n", diff: ['-w', '-U 3'])
      expect(diff.to_s).to eq <<-DIFF
  foo
-bar
+baz
      DIFF
    end
  end

  describe '#to_s' do
    describe 'with no line different' do
      it 'show everything' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbar\nbang\n"
        expect(described_class.new(string1, string2, allow_empty_diff: false).to_s).to eq <<-DIFF
 foo
 bar
 bang
        DIFF
      end
    end

    describe 'with one line different' do
      it 'show one line removed' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        expect(described_class.new(string1, string2).to_s).to eq <<-DIFF
 foo
-bar
 bang
        DIFF
      end

      it 'to_s accept a format key' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        expect(described_class.new(string1, string2).to_s(:color))
          .to eq(" foo\n\e[31m-bar\e[0m\n bang\n")
      end

      it 'accept a default format option' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        old_format = described_class.default_format
        described_class.default_format = :color
        expect(described_class.new(string1, string2).to_s)
          .to eq(" foo\n\e[31m-bar\e[0m\n bang\n")
        described_class.default_format = old_format
      end

      it 'accept a default options' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        old_options = described_class.default_options
        described_class.default_options = old_options.merge(include_diff_info: true)
        expect(described_class.new(string1, string2).to_s)
          .to include('@@ -1,3 +1,2 @@')
        described_class.default_options = old_options
      end

      it 'show one line added' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbang\n"
        expect(described_class.new(string2, string1).to_s)
          .to eq <<-DIFF
 foo
+bar
 bang
          DIFF
      end
    end

    describe 'with one line changed' do
      it 'show one line added and one removed' do
        string1 = "foo\nbar\nbang\n"
        string2 = "foo\nbong\nbang\n"
        expect(described_class.new(string1, string2).to_s).to eq <<-DIFF
 foo
-bar
+bong
 bang
        DIFF
      end
    end

    describe 'with totally different strings' do
      it 'show one line added and one removed' do
        string1 = "foo\nbar\nbang\n"
        string2 = "one\ntwo\nthree\n"
        expect(described_class.new(string1, string2).to_s).to eq <<-DIFF
-foo
-bar
-bang
+one
+two
+three
        DIFF
      end
    end

    describe 'with a somewhat complicated diff' do
      it 'show one line added and one removed' do
        string1 = "foo\nbar\nbang\nwoot\n"
        string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        diff = described_class.new(string1, string2)
        expect(diff.to_s).to eq <<-DIFF
-foo
+one
+two
+three
 bar
 bang
-woot
+baz
        DIFF
      end

      it 'make an awesome simple html diff' do
        string1 = "foo\nbar\nbang\nwoot\n"
        string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        diff = described_class.new(string1, string2)
        expect(diff.to_s(:html_simple)).to eq <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>foo</del></li>
    <li class="ins"><ins>one</ins></li>
    <li class="ins"><ins>two</ins></li>
    <li class="ins"><ins>three</ins></li>
    <li class="unchanged"><span>bar</span></li>
    <li class="unchanged"><span>bang</span></li>
    <li class="del"><del>woot</del></li>
    <li class="ins"><ins>baz</ins></li>
  </ul>
</div>
        HTML
      end

      it "accept overrides to diff's options" do
        string1 = "foo\nbar\nbang\nwoot\n"
        string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        diff = described_class.new(string1, string2, diff: '--rcs')
        expect(diff.to_s).to eq <<-DIFF
d1 1
a1 3
one
two
three
d4 1
a4 1
baz
        DIFF
      end
    end

    describe 'html' do
      it 'not allow html injection on the last line' do
        string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n<script>\n"
        string2 = "hahaha\nfruit flies like a banana\nbang baz\n<script>\n"
        diff = described_class.new(string1, string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
    <li class="unchanged"><span>&lt;script&gt;</span></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'highlight the changes within the line' do
        string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n"
        string2 = "hahaha\nfruit flies like a banana\nbang baz\n"
        diff = described_class.new(string1, string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'not duplicate some lines' do
        string1 = "hahaha\ntime flies like an arrow\n"
        string2 = "hahaha\nfruit flies like a banana\nbang baz"
        diff = described_class.new(string1, string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'escape html' do
        string1 = "ha<br>haha\ntime flies like an arrow\n"
        string2 = "ha<br>haha\nfruit flies like a banana\nbang baz"
        diff = described_class.new(string1, string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>ha&lt;br&gt;haha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="ins"><ins><strong>bang baz</strong></ins></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'not double escape html in wierd edge cases' do
        string1 = "preface = (! title .)+ title &{YYACCEPT}\n"
        string2 = "preface = << (! title .)+ title >> &{YYACCEPT}\n"
        diff = described_class.new string1, string2
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>preface = (! title .)+ title &amp;{YYACCEPT}</del></li>
    <li class="ins"><ins>preface = <strong>&lt;&lt; </strong>(! title .)+ title <strong>&gt;&gt; </strong>&amp;{YYACCEPT}</ins></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'highlight the changes within the line with windows style line breaks' do
        diff = described_class.new("hahaha\r\ntime flies like an arrow\r\nfoo bar\r\nbang baz\n", "hahaha\r\nfruit flies like a banana\r\nbang baz\n")
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>time</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo bar</strong></del></li>
    <li class="ins"><ins><strong>fruit</strong> flies like a<strong> banana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'treat unix vs windows newlines as differences' do
        diff = described_class.new("one\ntwo\nthree\n", "one\r\ntwo\r\nthree\r\n")
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="del"><del>one</del></li>
    <li class="del"><del>two</del></li>
    <li class="del"><del>three</del></li>
    <li class="ins"><ins>one<strong></strong></ins></li>
    <li class="ins"><ins>two<strong></strong></ins></li>
    <li class="ins"><ins>three<strong></strong></ins></li>
  </ul>
</div>
        HTML
        expect(diff.to_s(:html)).to eq(html)
      end

      it 'with lines that include \n not leave lines out' do
        expect(described_class.new("a\\nb\n", "acb\n").to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="del"><del>a<strong>\\n</strong>b</del></li>
    <li class="ins"><ins>a<strong>c</strong>b</ins></li>
  </ul>
</div>
        DIFF
      end

      it "do highlighting on the last line when there's no trailing newlines" do
        s1 = "foo\nbar\nbang"
        s2 = "foo\nbar\nbangleize"
        expect(described_class.new(s1, s2).to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="unchanged"><span>foo</span></li>
    <li class="unchanged"><span>bar</span></li>
    <li class="del"><del>bang</del></li>
    <li class="ins"><ins>bang<strong>leize</strong></ins></li>
  </ul>
</div>
        DIFF
      end

      it 'correctly do inline hightlighting when default diff options are changed' do
        original_options = described_class.default_options
        begin
          described_class.default_options[:diff] = '-U0'

          s1 = "foo\nbar\nbang"
          s2 = "foo\nbar\nbangleize"
          expect(described_class.new(s1, s2).to_s(:html)).to eq <<-DIFF
<div class="diff">
  <ul>
    <li class="del"><del>bang</del></li>
    <li class="ins"><ins>bang<strong>leize</strong></ins></li>
  </ul>
</div>
          DIFF
        ensure
          described_class.default_options = original_options
        end
      end
    end

    it 'escape diffed html in html output positive' do
      diff = described_class.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      expect(diff).to include('&lt;script&gt;')
    end

    it 'escape diffed html in html output negative' do
      diff = described_class.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      expect(diff).not_to include('<script>')
    end

    it 'be easy to generate custom format' do
      expect(described_class.new("foo\nbar\n", "foo\nbar\nbaz\n").map do |line|
        case line
        when /^\+/ then "line #{line.chomp} added"
        when /^-/ then "line #{line.chomp} removed"
        end
      end.compact.join).to eq('line +baz added')
    end

    it 'let you iterate over chunks instead of lines' do
      expect(described_class.new("foo\nbar\n", "foo\nbar\nbaz\n").each_chunk.map do |chunk|
        chunk
      end).to eq([" foo\n bar\n", "+baz\n"])
    end

    it 'allow chaining enumerable methods' do
      expect(described_class.new("foo\nbar\n", "foo\nbar\nbaz\n").each.map do |line|
        line
      end).to eq([" foo\n", " bar\n", "+baz\n"])
    end

    it 'handle lines that begin with --' do
      string1 = "a a\n-- b\nc c\n"
      string2 = "a a\nb b\nc c\n"

      expect(described_class.new(string1, string2).to_s).to eq <<-DIFF
 a a
--- b
+b b
 c c
      DIFF
    end

    it 'handle lines that begin with ++' do
      string1 = "a a\nb b\nc c\n"
      string2 = "a a\n++ b\nc c\n"

      expect(described_class.new(string1, string2).to_s).to eq <<-DIFF
 a a
-b b
+++ b
 c c
      DIFF
    end
  end
end
