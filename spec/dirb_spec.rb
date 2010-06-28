require 'spec'
require File.join(File.dirname(__FILE__), '..', 'lib', 'dirb')

describe Dirb do
  describe Diff do
    describe "#to_s" do
      describe "with one line different" do
        before do
          @string1 = "foo\nbar\nbang"
          @string2 = "foo\nbang"
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
          @string1 = "foo\nbar\nbang"
          @string2 = "foo\nbong\nbang"
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
    end
  end
end

