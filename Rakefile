require "bundler/gem_tasks"

task :default do
  sh "ruby test/email_address/*"
end
require "bundler/gem_tasks"
require "bundler/setup"
require 'rake/testtask'

task :default => :test

desc "Run the Test Suite, toot suite"
task :test do
  sh "ruby test/test_*"
end

desc "Open and IRB Console with the gem loaded"
task :console do
  sh "bundle exec irb  -Ilib -I . -r email_address"
  #require 'irb'
  #ARGV.clear
  #IRB.start
end
