IS_VAGRANT = File.expand_path("..", File.dirname(__FILE__)) == "/vagrant"
RAILS_ROOT = IS_VAGRANT ? "/vagrant/" : "/srv/www/slicer/current/"
PIDS_DIR = IS_VAGRANT ? File.join(RAILS_ROOT, "tmp", "pids") : "/srv/www/slicer/shared/pids/"

rails_env = ENV["RAILS_ENV"] || "development"
puts "\n"*3 + "#{rails_env}\n"*5 + "\n"*3

puts RAILS_ROOT
puts "#{PIDS_DIR}\n"*10

require "fileutils"
FileUtils.mkpath(PIDS_DIR)
FileUtils.mkpath("#{RAILS_ROOT}/log/")

#Bluepill.application("app", :foreground => true) do |app| # For Debugging
Bluepill.application("app", :log_file => "#{RAILS_ROOT}/log/bluepill.log") do |app|

  app.working_dir = RAILS_ROOT
  app.uid = IS_VAGRANT ? "vagrant" : "ubuntu"
  app.gid = IS_VAGRANT ? "vagrant" : "ubuntu"


  app.process("unicorn") do |process|
    process.group = "app"

    process.pid_file = File.join(PIDS_DIR, 'unicorn.pid')
    process.working_dir = RAILS_ROOT
    process.environment = { 'RAILS_ENV' => rails_env }
    process.stdout = process.stderr = "#{RAILS_ROOT}/log/bluepill_unicorn.log"

    process.start_command = "unicorn -Dc config/unicorn.rb"
    process.stop_command = "kill {{PID}}"
    process.restart_command = "kill {{PID}}; unicorn -Dc config/unicorn.rb" # Lots of Downtime. Works like a charm.
    # process.restart_command = "unicorn -Dc config/unicorn.rb" # Zero Downtime. Entirely Broken.

    process.start_grace_time = 8.seconds
    process.stop_grace_time = 5.seconds
    process.restart_grace_time = 13.seconds

    process.monitor_children do |child_process|
      child_process.stop_command = "kill -QUIT {{PID}}"

      child_process.checks :mem_usage, :every => 10.seconds, :below => 150.megabytes, :times => [3,4], :fires => :stop
      child_process.checks :cpu_usage, :every => 10.seconds, :below => 20, :times => [3,4], :fires => :stop
    end
  end


  app.process("pubsub") do |process|
    process.pid_file = File.join(PIDS_DIR, 'private_pub_sub.pid')
    process.start_command = "rackup private_pub.ru -s thin -E production --daemonize -P \"#{process.pid_file}\""
    process.group = "app"
    process.stop_command = "kill -9 {{PID}}"

    process.start_grace_time = 8.seconds
    process.stop_grace_time = 5.seconds
    process.restart_grace_time = 13.seconds
  end


  app.process("resque") do |process|
    process.group = "app"
    process.environment = { 'RAILS_ENV' => rails_env }

    process.pid_file = File.join(PIDS_DIR, 'resque.pid')
    process.start_command = "bundle exec rake environment resque:work"
    process.stop_command = "kill -QUIT {{PID}}"
    process.daemonize = true

    process.start_grace_time = 8.seconds
    process.stop_grace_time = 5.seconds
    process.restart_grace_time = 13.seconds

  end

end
