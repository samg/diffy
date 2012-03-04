require 'tempfile'
require 'open3'
require 'erb'
# 1.9 compatibility
if defined? Enumerator and ! defined? Enumerable::Enumerator
  Enumerable::Enumerator = Enumerator
end

module Diffy; end
require File.join(File.dirname(__FILE__), 'diffy', 'format')
require File.join(File.dirname(__FILE__), 'diffy', 'html_formatter')
require File.join(File.dirname(__FILE__), 'diffy', 'diff')
require File.join(File.dirname(__FILE__), 'diffy', 'css')
