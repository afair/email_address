$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'active_record'
require 'rubygems'
require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/pride'
require 'email_address'
