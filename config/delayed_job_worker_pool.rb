require 'sd_notify'

# Notify systemd that we are the main process
SdNotify.mainpid Process.pid

require 'etc'

worker_group do |group|
  group.workers = Integer(ENV['NUM_WORKERS'] || Etc.nprocessors)
  group.queues = (ENV['QUEUES'] || ENV['QUEUE'] || '').split(',')
end

preload_app

# This runs in the master process after it preloads the app
after_preload_app do
  puts "Master #{Process.pid} preloaded app"

  # Don't hang on to database connections from the master after we've completed initialization
  ActiveRecord::Base.connection_pool.disconnect!

  if SdNotify.watchdog?
    watchdog_thread_sleep_interval = Integer(ENV['WATCHDOG_USEC']) / 2000000

    # Start the watchdog thread with high priority
    Thread.new do
      loop do
        sleep watchdog_thread_sleep_interval

        SdNotify.watchdog
      end
    end.priority = Integer(ENV['WATCHDOG_PRIORITY'] || 100)
  end

  # Notify systemd of our PID and that we have finished booting up
  SdNotify.ready
end

# This runs in the worker processes after they have been forked
on_worker_boot do |worker_info|
  puts "Worker #{Process.pid} started"

  # Reconnect to the database
  ActiveRecord::Base.establish_connection
end

# This runs in the master process after a worker starts
after_worker_boot do |worker_info|
  puts "Master #{Process.pid} booted worker #{worker_info.name} with " \
       "process id #{worker_info.process_id}"
end

# This runs in the master process after a worker shuts down
after_worker_shutdown do |worker_info|
  puts "Master #{Process.pid} detected dead worker #{worker_info.name} " \
       "with process id #{worker_info.process_id}"
end

# Monkeypatch to notify systemd when delayed_job_worker_pool is stopping (no hooks exist)
DelayedJobWorkerPool::WorkerPool.class_exec do
  private

  def shutdown(signal)
    SdNotify.stopping
    log("Shutting down master #{Process.pid} with signal #{signal}")
    self.shutting_down = true
    registry.worker_pids.each do |child_pid|
      group = registry.group(child_pid)
      log("Telling worker #{child_pid} from group #{group} to shutdown with signal #{signal}")
      Process.kill(signal, child_pid)
    end
  end
end
