require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'dirb')

describe Dirb::Diff do
  describe "#to_s" do
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

      it "should make an awesome html diff" do
        @diff.to_html.should == <<-HTML
<ul class="diff">
  <li><del>foo</del></li>
  <li><ins>one</ins></li>
  <li><ins>two</ins></li>
  <li><ins>three</ins></li>
  <li>bar</li>
  <li>bang</li>
  <li><del>woot</del></li>
  <li><ins>baz</ins></li>
</ul>
        HTML

      end
    end
  end
end

