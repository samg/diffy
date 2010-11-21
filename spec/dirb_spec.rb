require 'spec'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'dirb'))

describe Dirb::Diff do
  describe "#to_s" do
    describe "with no line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbar\nbang\n"
      end

      it "should show everything" do
        Dirb::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
 bar
 bang
        DIFF
      end
    end
    describe "with one line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbang\n"
      end

      it "should show one line removed" do
        Dirb::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
-bar
 bang
        DIFF
      end

      it "to_s should accept a format key" do
        Dirb::Diff.new(@string1, @string2).to_s(:color).
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
      end

      it "should accept a default format option" do
        old_format = Dirb::Diff.default_format
        Dirb::Diff.default_format = :color
        Dirb::Diff.new(@string1, @string2).to_s.
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
        Dirb::Diff.default_format = old_format
      end

      it "should show one line added" do
        Dirb::Diff.new(@string2, @string1).to_s.should == <<-DIFF
 foo
+bar
 bang
        DIFF
      end
    end

    describe "with one line changed" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbong\nbang\n"
      end
      it "should show one line added and one removed" do
        Dirb::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
-bar
+bong
 bang
        DIFF
      end
    end

    describe "with totally different strings" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "one\ntwo\nthree\n"
      end
      it "should show one line added and one removed" do
        Dirb::Diff.new(@string1, @string2).to_s.should == <<-DIFF
-foo
-bar
-bang
+one
+two
+three
        DIFF
      end
    end

    describe "with a somewhat complicated diff" do
      before do
        @string1 = "foo\nbar\nbang\nwoot\n"
        @string2 = "one\ntwo\nthree\nbar\nbang\nbaz\n"
        @diff = Dirb::Diff.new(@string1, @string2)
      end
      it "should show one line added and one removed" do
        @diff.to_s.should == <<-DIFF
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

      it "should make an awesome simple html diff" do
        @diff.to_s(:html_simple).should == <<-HTML
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

      it "should accept overrides to diff's options" do
        @diff = Dirb::Diff.new(@string1, @string2, "--rcs")
        @diff.to_s.should == <<-DIFF
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

    describe "html" do

      it "should highlight the changes within the line" do
        @string1 = "hahaha\ntime flies like an arrow\nfoo bar\nbang baz\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz\n"
        @diff = Dirb::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>t</strong>i<strong>me</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo</strong> ba<strong>r</strong></del></li>
    <li class="ins"><ins><strong>fru</strong>i<strong>t</strong> flies like a ba<strong>nana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should not duplicate some lines" do
        @string1 = "hahaha\ntime flies like an arrow\n"
        @string2 = "hahaha\nfruit flies like a banana\nbang baz"
        @diff = Dirb::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>t</strong>i<strong>me</strong> flies like an a<strong>rrow</strong></del></li>
    <li class="ins"><ins><strong>fru</strong>i<strong>t</strong> flies like a<strong> ba</strong>n<strong>ana</strong></ins></li>
    <li class="ins"><ins><strong>bang</strong> <strong>b</strong>a<strong>z</strong></ins></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should escape html" do
        @string1 = "ha<br>haha\ntime flies like an arrow\n"
        @string2 = "ha<br>haha\nfruit flies like a banana\nbang baz"
        @diff = Dirb::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>ha&lt;br&gt;haha</span></li>
    <li class="del"><del><strong>t</strong>i<strong>me</strong> flies like an a<strong>rrow</strong></del></li>
    <li class="ins"><ins><strong>fru</strong>i<strong>t</strong> flies like a<strong> ba</strong>n<strong>ana</strong></ins></li>
    <li class="ins"><ins><strong>bang</strong> <strong>b</strong>a<strong>z</strong></ins></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end

      it "should highlight the changes within the line with windows style line breaks" do
        @string1 = "hahaha\r\ntime flies like an arrow\r\nfoo bar\r\nbang baz\n"
        @string2 = "hahaha\r\nfruit flies like a banana\r\nbang baz\n"
        @diff = Dirb::Diff.new(@string1, @string2)
        html = <<-HTML
<div class="diff">
  <ul>
    <li class="unchanged"><span>hahaha</span></li>
    <li class="del"><del><strong>t</strong>i<strong>me</strong> flies like a<strong>n arrow</strong></del></li>
    <li class="del"><del><strong>foo</strong> ba<strong>r</strong></del></li>
    <li class="ins"><ins><strong>fru</strong>i<strong>t</strong> flies like a ba<strong>nana</strong></ins></li>
    <li class="unchanged"><span>bang baz</span></li>
  </ul>
</div>
        HTML
        @diff.to_s(:html).should ==  html
      end
    end

    it "should escape diffed html in html output" do
      diff = Dirb::Diff.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      diff.should include('&lt;script&gt;')
      diff.should_not include('<script>')
    end

    it "should be easy to generate custom format" do
      Dirb::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").map do |line|
        case line
        when /^\+/ then "line #{line.chomp} added"
        when /^-/ then "line #{line.chomp} removed"
        end
      end.compact.join.should == "line +baz added"
    end

    it "should let you iterate over chunks instead of lines" do
      Dirb::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each_chunk.map do |chunk|
        chunk
      end.should == [" foo\n bar\n", "+baz\n"]
    end

    it "should allow chaining enumerable methods" do
      Dirb::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each.map do |line|
        line
      end.should == [" foo\n", " bar\n", "+baz\n"]
    end
  end
end

