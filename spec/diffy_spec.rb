require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'diffy')

describe Diffy::Diff do
  describe "#to_s" do
    describe "with no line different" do
      before do
        @string1 = "foo\nbar\nbang\n"
        @string2 = "foo\nbar\nbang\n"
      end

      it "should show everything" do
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
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
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
 foo
-bar
 bang
        DIFF
      end

      it "to_s should accept a format key" do
        Diffy::Diff.new(@string1, @string2).to_s(:color).
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
      end

      it "should accept a default format option" do
        old_format = Diffy::Diff.default_format
        Diffy::Diff.default_format = :color
        Diffy::Diff.new(@string1, @string2).to_s.
          should == " foo\n\e[31m-bar\e[0m\n bang\n"
        Diffy::Diff.default_format = old_format
      end

      it "should show one line added" do
        Diffy::Diff.new(@string2, @string1).to_s.should == <<-DIFF
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
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
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
        Diffy::Diff.new(@string1, @string2).to_s.should == <<-DIFF
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
        @diff = Diffy::Diff.new(@string1, @string2)
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

      it "should make an awesome html diff" do
        @diff.to_s(:html).should == <<-HTML
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
        @diff = Diffy::Diff.new(@string1, @string2, "--rcs")
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

    it "should escape diffed html in html output" do
      diff = Diffy::Diff.new("<script>alert('bar')</script>", "<script>alert('foo')</script>").to_s(:html)
      diff.should include('&lt;script&gt;')
      diff.should_not include('<script>')
    end

    it "should be easy to generate custom format" do
      Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").map do |line|
        case line
        when /^\+/ then "line #{line.chomp} added"
        when /^-/ then "line #{line.chomp} removed"
        end
      end.compact.join.should == "line +baz added"
    end
  end
end

