require 'time'
sample_size = 10

results = (1..8).collect do |threads|

  puts "Running #{sample_size} tests with #{threads} threads.."

#  times = (1..sample_size).map{ %x[time -p ls 2>&1].match(/real\s*([0-9.]+)/)[1]}

  times = (1..sample_size).map{ %x[time -p ./slic3r.pl -j #{threads} ~/ImplicitCAD/test.stl ./test.gcode 2>&1].match(/real\s*([0-9.]+)/)[1]}
  average = times.collect(&:to_f).inject(&:+) / times.count

end

puts "Slic3r Performance Results"
puts "\n\n\n#{"-"*40}\n\n"

results.each_with_index do |average, threads|
  puts "#{threads+1} Threads: #{average}ms average with a sample size of #{sample_size}"
end