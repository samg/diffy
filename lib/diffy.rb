require 'tempfile'
require 'erb'
require 'rbconfig'
# 1.9 compatibility
if defined? Enumerator and ! defined? Enumerable::Enumerator
  Enumerable::Enumerator = Enumerator
end

module Diffy
  WINDOWS = (RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/)
end
require 'open3' unless Diffy::WINDOWS
require File.join(File.dirname(__FILE__), 'diffy', 'format')
require File.join(File.dirname(__FILE__), 'diffy', 'html_formatter')
require File.join(File.dirname(__FILE__), 'diffy', 'diff')
require File.join(File.dirname(__FILE__), 'diffy', 'css')
