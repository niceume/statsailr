load("./sts_scanner.rb")

s = StatSailr::ScanDriver.new("./sample1.sts")
tokens = s.tokenize()
puts "Showing tokens"

require "pp"
pp tokens
