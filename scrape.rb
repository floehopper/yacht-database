require 'open-uri'

path = Pathname.new('sailboatdata')
path.mkpath

(1..8933).each do |id|
  io = open("http://sailboatdata.com/viewrecord.asp?class_id=#{id}")
  File.write(path.join("#{id}.html"), io.read)
  sleep 1
  p id
rescue OpenURI::HTTPError => e
  p [id, e]
end
