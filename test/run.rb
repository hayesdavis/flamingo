#!/usr/bin/env ruby

$: << File.expand_path(File.dirname(__FILE__))
require "test_helper"

if ARGV.empty?
  Dir.glob("#{File.dirname(__FILE__)}/**/*_test.rb") do |file|
    require File.expand_path(file)
  end
else
  ARGV.each do |file|
    require(file)
  end
end