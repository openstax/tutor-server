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
