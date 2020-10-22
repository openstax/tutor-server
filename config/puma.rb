# https://gitlab.com/gitlab-org/gitlab-foss/-/blob/multi-threading/config/puma.rb.example

APP_DIR = File.expand_path('..', __dir__)
directory APP_DIR

tag 'OpenStax Tutor Puma'

NUM_WORKERS = ENV.fetch('PUMA_NUM_WORKERS') { Etc.nprocessors }.to_i

worker_timeout ENV.fetch('PUMA_WORKER_TIMEOUT', 60).to_i

stdout_redirect(
  ENV.fetch('PUMA_STDOUT_LOGFILE', "#{APP_DIR}/log/puma.stdout.log"),
  ENV.fetch('PUMA_STDERR_LOGFILE', "#{APP_DIR}/log/puma.stderr.log"),
  true
) if ENV.fetch('PUMA_REDIRECT_STDOUT', false)

before_fork do
  require 'puma_worker_killer'

  PumaWorkerKiller.config do |config|
    # Restart workers when they start consuming more than 1G each
    config.ram = ENV.fetch('PUMA_MAX_MEMORY') do
      ENV.fetch('PUMA_MAX_WORKER_MEMORY', 1024).to_i * NUM_WORKERS
    end.to_i

    config.frequency = 10

    config.percent_usage = 1.0

    config.rolling_restart_frequency = false

    config.reaper_status_logs = false
  end

  PumaWorkerKiller.start
end

# https://github.com/rails/rails/blob/master/railties/lib/rails/generators/rails/app/templates/config/puma.rb.tt

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads = ENV.fetch('PUMA_MAX_THREADS', 5).to_i
threads ENV.fetch('PUMA_MIN_THREADS', max_threads_count).to_i, max_threads

if ENV['PUMA_SOCKET']
  # Specifies the `socket` to which Puma will bind to receive requests.
  #
  bind ENV['PUMA_SOCKET']
else
  # Specifies the `port` that Puma will listen on to receive requests; default is 3000.
  #
  port ENV.fetch('PUMA_PORT', 3001)
end

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
#
pidfile ENV.fetch('PUMA_PIDFILE', 'tmp/pids/puma.pid')

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers NUM_WORKERS

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if ENV.fetch('PUMA_PRELOAD_APP', false)

# Allow puma to be restarted by `rails restart` command.
#
plugin :tmp_restart
