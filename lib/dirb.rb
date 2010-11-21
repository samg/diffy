require 'tempfile'
require 'open3'
require 'erb'
# 1.9 compatibility
if defined? Enumerator and ! defined? Enumerable::Enumerator
  Enumerable::Enumerator = Enumerator
end

module Dirb; end
require File.join(File.dirname(__FILE__), 'dirb', 'format')
require File.join(File.dirname(__FILE__), 'dirb', 'html_formatter')
require File.join(File.dirname(__FILE__), 'dirb', 'diff')
