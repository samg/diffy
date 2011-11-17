Diffy - Easy Diffing With Ruby
============================

Need diffs in your ruby app?  Diffy has you covered.  It provides a convenient
way to generate a diff from two strings or files.  Instead of reimplementing
the LCS diff algorithm Diffy uses battle tested Unix diff to generate diffs,
and focuses on providing a convenient interface, and getting out of your way.

Supported Formats
-----------------

It provides several built in format options which can be passed to
`Diffy::Diff#to_s`.

* `:text`         - Plain text output
* `:color`        - ANSI colorized text suitable for use in a terminal
* `:html`         - HTML output.  Since version 2.0 this format does inline highlighting of the changes between two the changes within lines.
* `:html_simple`  - HTML output without inline highlighting.  This may be useful in situations where high performance is required or simpler output is desired.

A default format can be set like so:

    Diffy::Diff.default_format = :html

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

    >> puts Diffy::Diff.new(string1, string2).to_s(:html_simple)
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
    .diff li{padding:0; display:table-row;margin: 0;height:1em;}
    .diff li.ins{background:#dfd; color:#080}
    .diff li.del{background:#fee; color:#b00}
    .diff li:hover{background:#ffc}
    /* try 'whitespace:pre;' if you don't want lines to wrap */
    .diff del, .diff ins, .diff span{white-space:pre-wrap;font-family:courier;}
    .diff del strong{font-weight:normal;background:#fcc;}
    .diff ins strong{font-weight:normal;background:#9f9;}
    .diff li.diff-comment { display: none; }
    .diff li.diff-block-info { background: none repeat scroll 0 0 gray; }

You can also diff files instead of strings

    >> puts Diffy::Diff.new('/tmp/foo', '/tmp/bar', :source => 'files')

Custom Formats
--------------

Diffy tries to make generating your own custom formatted output easy.
`Diffy::Diff` provides an enumberable interface which lets you iterate over
lines in the diff.

    >> Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n").each do |line|
    >*   case line
    >>   when /^\+/ then puts "line #{line.chomp} added"
    >>   when /^-/ then puts "line #{line.chomp} removed"
    >>   end
    >> end
    line +baz added
    => [" foo\n", " bar\n", "+baz\n"]

You can also use `Diffy::Diff#each_chunk` to iterate each grouping of additions,
deletions, and unchanged in a diff.

    >> Diffy::Diff.new("foo\nbar\nbang\nbaz\n", "foo\nbar\nbing\nbong\n").each_chunk.to_a
    => [" foo\n bar\n", "-bang\n-baz\n", "+bing\n+bong\n"]

Use `#map`, `#inject`, or any of Enumerable's methods.  Go crazy.

Full Diff Output
----------------

By default diffy removes the superfluous diff output.  This is because its default is to show the complete diff'ed file (`diff -U 1000` is the default).

Diffy does support full output, just use the `:include_diff_info => true` option when initializing:

  >> Diffy::Diff.new("foo\nbar\n", "foo\nbar\nbaz\n", :include_diff_info => true).to_s(:text)

And even deals a bit with the formatting!

Ruby Version Compatibility
-------------------------

Support for Ruby 1.8.6 was dropped beggining at version 2.0 in order to support
the chainable enumerators available in 1.8.7 and 1.9.

If you want to use Diffy and Ruby 1.8.6 then:

    $ gem install diffy -v1.1.0

---------------------------------------------------------------------

Report bugs or request features at http://github.com/samg/diffy/issues

