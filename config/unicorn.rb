# config/unicorn.rb

APP_DIR = File.expand_path('../', __dir__)

worker_processes ENV.fetch('UNICORN_WORKER_PROCESSES', 3)
timeout ENV.fetch('UNICORN_TIMEOUT', 300)
preload_app ENV.fetch('UNICORN_PRELOAD_APP', false)
working_directory APP_DIR

# unicorn file locations
pid ENV.fetch('UNICORN_PID_PATH', "#{APP_DIR}/tmp/pids/unicorn.pid")
unless ENV.fetch('UNICORN_LOG_TO_STDOUT', true)
  stderr_path "#{APP_DIR}/log/unicorn.stderr.log"
  stdout_path "#{APP_DIR}/log/unicorn.stdout.log"
end

before_fork do |server, worker|
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
