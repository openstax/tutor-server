# https://gitlab.com/gitlab-org/gitlab-foss/-/blob/multi-threading/config/puma.rb.example

APP_DIR = File.expand_path('../', __dir__)
directory APP_DIR

stdout_redirect(
  "#{APP_DIR}/log/puma.stdout.log", "#{APP_DIR}/log/puma.stderr.log", true
) if ENV.fetch('REDIRECT_STDOUT', false)

tag 'OpenStax Tutor Puma'

worker_timeout ENV.fetch('TIMEOUT', 300)

NUM_WORKERS = ENV.fetch('WEB_CONCURRENCY') { Etc.nprocessors }.to_i

before_fork do
  require 'puma_worker_killer'

  PumaWorkerKiller.config do |config|
    # Restart workers when they start consuming more than 1G each
    config.ram = ENV.fetch('MAX_MEMORY') do
      ENV.fetch('MAX_MEMORY_PER_WORKER', 1024).to_i * NUM_WORKERS
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
max_threads_count = ENV.fetch('RAILS_MAX_THREADS', 5)
min_threads_count = ENV.fetch('RAILS_MIN_THREADS', max_threads_count)
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch('PORT', 3001)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch('RAILS_ENV', 'development')

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch('PIDFILE', 'tmp/pids/puma.pid')

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
preload_app! if ENV.fetch('PRELOAD_APP', false)

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
