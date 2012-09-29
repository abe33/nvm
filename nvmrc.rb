require 'rubygems'
require 'json'

require "#{File.dirname(__FILE__)}/selector"

begin
  package = JSON.parse(File.read(ARGV.first))
  if package['engine'] && package['engine']['node']
    expected_version = package['engine']['node']
    available_versions = STDIN.read.split("\n").map {|v| v.gsub('v', '')}

    selector = VersionSelector.new available_versions
    version = selector.match expected_version
    if version
      print "nvm use v#{version}"
    else
      print "No version found"
    end
  else
    print "package.json present but no engine specified"
  end
rescue => e
  print "#{e} at #{e.backtrace}"
end
