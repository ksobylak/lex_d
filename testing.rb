require 'net/http'

uri = URI('http://localhost:4567/document/whatever')

result = Net::HTTP.get(uri)

puts result.to_f