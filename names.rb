# ruby names.rb
# >June 19 15:17 ca/cfefd7... php-caret [4,9,13] -> 26 
# >June 29 19:05 f6/893527... dojo-name [0,1,3] -> 4
# Columns are: Date, Time, Folder, Name, [Increments per avatar], Total Number of Increments, Browser

require 'digest/sha1'

def recent(array, max_length)
  len = [array.length, max_length].min
  array[-len,len]
end

def avatars
  %w( alligator buffalo cheetah elephant frog giraffe hippo lion raccoon snake wolf zebra 
      gopher koala squirrel moose bear bat camel lemur panda gorilla deer kangaroo )
end

index = eval IO.popen('cat katas/index.rb').read
show = (ARGV[0] || "32").to_i
names = recent(index, show).map{|e| e[:name]}
names.each do |name|
  sha1 = Digest::SHA1.hexdigest(name)
  inner = sha1[0..1]   
  outer = sha1[2..-1]
  path = "dojos/#{inner}/#{outer}"
  manifest = eval IO.popen("cat #{path}/manifest.rb").read
  created = Time.mktime(*manifest[:created])

  inc_lengths = []
  avatars.each do |avatar|
    if File.directory? path + '/' + avatar
      incs = eval IO.popen("cat #{path}/#{avatar}/increments.rb").read
      inc_lengths << incs.length
    end
  end

  print created.strftime('%b %d %H:%M') + 
    ' ' + inner + '/' + outer[0..6] + '...' + 
    ' ' + name + ', ' +
    ' ' + manifest[:language] + ', ' +
    ' ' + manifest[:kata] + ', ' +
    ' ' + '[' + inc_lengths.sort.join(',') + '] -> ' + inc_lengths.reduce(:+).to_s +
    ' ' + (manifest[:browser] || "") +
    "\n"

end