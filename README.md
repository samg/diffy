Diffy - Easy Diffing With Ruby
============================

Need diffs in your ruby app?  Diffy has you covered.  It provides a convenient
way to generate a diff from two strings.  Instead of reimplementing the LCS diff
algorithm Diffy uses battle tested Unix diff to generate diffs, and focuses on
providing a convenient interface, and getting out of your way.

It provides several built in format options.  Pass `:text`, `:color`, or
`:html` to `Diffy::Diff#to_s` to force that format, or set
`Diffy::Diff.default_format`

Getting Started
---------------

    sudo gem install diffy

Here's an example of using Diffy to diff two strings

    $ irb
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
    >> puts Diffy::Diff.new(string1, string2)
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell

Outputing the diff as html is easy too.

    >> puts Diffy::Diff.new(string1, string2).to_s(:html)
    <div class="diff">
      <ul>
        <li class="del"><del>Hello how are you</del></li>
        <li class="ins"><ins>Hello how are you?</ins></li>
        <li class="unchanged"><span>I'm fine</span></li>
        <li class="del"><del>That's great</del></li>
        <li class="ins"><ins>That's swell</ins></li>
      </ul>
    </div>

Then try adding this css to your stylesheets:

    .diff{overflow:auto;}
    .diff ul{background:#fff;overflow:auto;font-size:13px;list-style:none;margin:0;padding:0;display:table;width:100%;}
    .diff del, .diff ins{display:block;text-decoration:none;}
    .diff li{padding:0; display:table-row;margin: 0;}
    .diff li.ins{background:#9f9;}
    .diff li.del{background:#ccf;}
    .diff li:hover{background:#ffc}
    .diff del, .diff ins, .diff span{white-space:pre;font-family:courier;}

`Diffy::Diff` also alows you to set a default format.  Here we set the default to
use ANSI termnial color escape sequences.

    >> Diffy::Diff.default_format = :color
    => :color
    >> puts Diffy::Diff.new(string1, string2) # prints color in the terminal
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell


Creating custom formatted output is easy too.  `Diffy::Diff` provides an
enumberable interface which lets you iterate over lines in the diff.

    >> Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each do |line|
    >*   case line
    >>   when /^\+/ then puts "line #{line.chomp} added"
    >>   when /^-/ then puts "line #{line.chomp} removed"
    >>   end
    >> end
    line +baz added
    => [" foo\n", " bar\n", "+baz\n"]

Use `#map`, `#inject`, or any of Enumerable's methods.  Go crazy.

Report bugs or request features at http://github.com/samg/Diffy/issues

