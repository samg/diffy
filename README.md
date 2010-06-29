Dirb - Easy Diffing With Ruby
============================

Need diffs in your ruby app?  Dirb has you covered.  It provides a convenient
way to generate a diff from two strings.  Instead of reimplementing the LCS diff
algorithm Dirb uses battle tested Unix diff to generate diffs, and focuses on
providing a convenient interface, and getting out of your way.

It provides several built in format options.  Pass `:text`, `:color`, or
`:html` to `Dirb::Diff#to_s` to force that format, or set
`Dirb::Diff.default_format`

    $ irb
    >> require 'rubygems'
    >> require 'dirb'
    => true
    >> string1 = <<-TXT
    >" Hello how are you
    >" I'm fine
    >" That's great
    >" TXT
    => "Hello how are you\nI'm fine\nThat's great\n"
    >> string2 = <<-TXT
    >" Hello how are you?
    >" I'm fine
    >" That's swell
    >" TXT
    => "Hello how are you?\nI'm fine\nThat's swell\n"
    >> puts Dirb::Diff.new(string1, string2)
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell
    => nil
    >> puts Dirb::Diff.new(string1, string2).to_s(:html)
    <ul class="diff">
      <li class="del"><del>Hello how are you</del></li>
      <li class="ins"><ins>Hello how are you?</ins></li>
      <li class="unchanged"><span>I'm fine</span></li>
      <li class="del"><del>That's great</del></li>
      <li class="ins"><ins>That's swell</ins></li>
    </ul>
    => nil
    >> Dirb::Diff.default_format = :color
    => :color
    irb(main):015:0> puts Dirb::Diff.new(string1, string2) # prints color in the terminal
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell
    => nil


Creating custom formatted output is easy too.  `Dirb::Diff` provides an
enumberable interface which lets you iterate over lines in the diff.

    >> Dirb::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each do |line|
    >*   case line
    >>   when /^\+/ then puts "line #{line.chomp} added"
    >>   when /^-/ then puts "line #{line.chomp} removed"
    >>   end
    >> end
    line +baz added
    => [" foo\n", " bar\n", "+baz\n"]

Use `#map`, `#inject`, or any of Enumerable's methods.  Go crazy.

Report bugs or request features at http://github.com/samg/Dirb/issues

