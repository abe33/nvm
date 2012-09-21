require 'rubygems'
require 'json'

begin
  package = JSON.parse(File.read(ARGV.first))
  if package['engine'] && package['engine']['node']
    expected_version = package['engine']['node']
    available_versions = STDIN.read.split("\n")

    re = /^(>=|<=|=)*(\d+(\.\d+(\.\d+(-.*)*)*)*)/
    m = re.match expected_version
    if m
      op, version = m[1], m[2]

      op = "==" if op == "=" || op == ''

      compatible_versions = available_versions.select do |v|
        eval "'#{v}' #{op} 'v#{version}'"
      end

      if compatible_versions.empty?
        print "No compatible version available"
      else
        preferred_version = compatible_versions.max

        print "nvm use #{preferred_version}"
      end
    else
      print "Invalid version expression"
    end
  else
    print "package.json present but no engine specified"
  end
rescue => e
  print "#{e} at #{e.backtrace}"
end
