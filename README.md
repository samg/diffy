Dirb - Easy Diffing With Ruby
============================

Need diffs in your ruby app?  Dirb has you covered.  It provides a convenient
way to generate a diff from two strings.  Instead of reimplementing the LCS diff
algorithm Dirb uses battle tested Unix diff to generate diffs, and focuses on
providing a convenient interface, and getting out of your way.

Supported Formats
-----------------

It provides several built in format options which can be passed to
`Dirb::Diff#to_s`.

* `:text`         - Plain text output
* `:color`        - ANSI colorized text suitable for use in a terminal
* `:html`         - HTML output.  Since version 2.0 this format does inline
                    highlighting of the changes between two the changes within
                    lines.
* `:html_simple`  - HTML output without inline highlighting.  This may be
                    useful in situations where high performance is required or
                    simpler output is desired.

A default format can be set like so:

    `Dirb::Diff.default_format = :html`

Getting Started
---------------

    sudo gem install dirb

Here's an example of using Dirb to diff two strings

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
    >> puts Dirb::Diff.new(string1, string2)
    -Hello how are you
    +Hello how are you?
     I'm fine
    -That's great
    +That's swell

Outputing the diff as html is easy too.

    >> puts Dirb::Diff.new(string1, string2).to_s(:html_simple)
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
    .diff del, .diff ins, .diff span{white-space:pre;font-family:courier;}
    .diff li.ins{background:#9f9;}
    .diff li.del{background:#fcc;}
    .diff li.ins strong{font-weight:normal; background: #6f6 }
    .diff li.del strong{font-weight:normal; background: #f99 }

Custom Formats
--------------

Dirb tries to make generating your own custom formatted output easy too.
`Dirb::Diff` provides an enumberable interface which lets you iterate over
lines in the diff.

    >> Dirb::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each do |line|
    >*   case line
    >>   when /^\+/ then puts "line #{line.chomp} added"
    >>   when /^-/ then puts "line #{line.chomp} removed"
    >>   end
    >> end
    line +baz added
    => [" foo\n", " bar\n", "+baz\n"]

You can also use `Dirb::Diff#each_chunk` to iterate each grouping of additions,
deletions, and unchanged in a diff.

    >> Dirb::Diff.new("foo\nbar\nbang\nbaz\n", "foo\nbar\nbing\nbong\n").each_chunk.to_a
    => [" foo\n bar\n", "-bang\n-baz\n", "+bing\n+bong\n"]

Use `#map`, `#inject`, or any of Enumerable's methods.  Go crazy.

Ruby Version Compatibility
-------------------------

Support for Ruby 1.8.6 was dropped beggining at version 2.0 in order to support
the chainable enumerators available in 1.8.7 and 1.9.

If you want to use Dirb and Ruby 1.8.6 then:

    $ gem install dirb -v1.1.0

---------------------------------------------------------------------

Report bugs or request features at http://github.com/samg/Dirb/issues

