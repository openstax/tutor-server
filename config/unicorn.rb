# config/unicorn.rb

APP_DIR = File.expand_path("../../", __FILE__)

worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 300
preload_app true
working_directory APP_DIR

listen 3000

# unicorn file locations
pid "#{APP_DIR}/tmp/pids/unicorn.pid"
stderr_path "#{APP_DIR}/log/unicorn.stderr.log"
stdout_path "#{APP_DIR}/log/unicorn.stdout.log"


before_fork do |server, worker|
  # disconnect the unicorn master from the db before forking
  ActiveRecord::Base.connection.disconnect! if defined?(ActiveRecord::Base)

  # when sent a USR2, unicorn will suffix its pidfile with .oldbin and load a new version of itself
  # as this new master process spawns workers, it will check if a .oldbin pidfile exists
  # if it does, it will send a QUIT signal to the old unicorn master
  # this method allows zero downtime deployments with a single server
  old_pid = "#{server.config[:pid]}.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # the old unicorn master process no longer exists
    end
  end
end

after_fork do |server, worker|
  # unicorn master loads the app then forks off workers
  # we need to make sure we aren't using any of the parent's sockets, e.g. db connection
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord::Base)
end
