desc <<-DESC.strip_heredoc
  Initializes data for the deployment demo (run all demo:* tasks)
  Book can be either all, bio, phys or soc.
DESC
task :demo, [ :config, :version, :random_seed ] => :log_to_stdout do |tt, args|
  Rake::Task[:'demo:staff'].invoke unless ENV['SKIP_STAFF']
  Rake::Task[:'demo:books'].invoke(args[:config], args[:version]) unless ENV['SKIP_BOOKS']

  unless ENV['SKIP_COURSES']
    Rake::Task[:'demo:courses'].invoke(args[:config])

    unless ENV['SKIP_TASKS']
      Rake::Task[:'demo:tasks'].invoke(args[:config], args[:random_seed])

      Rake::Task[:'demo:work'].invoke(args[:config], args[:random_seed]) unless ENV['SKIP_WORK']
    end
  end

  log_background_job_info configs.size
  log_worker_mem_info
end

namespace :demo do
  def log_background_job_info(num_jobs)
    Rails.logger.info do
      "#{num_jobs} background job(s) queued\n" +
      "Manage background workers: bin/delayed_job -n #{num_jobs} status/start/stop\n" +
      'Check job status: bin/rake jobs:status'
    end
  end

  def log_worker_mem_info
    Rails.logger.info { 'Make sure you have ~4G free memory per background worker' }
  end

  desc 'Creates demo staff user accounts'
  task staff: :log_to_stdout do |tt, args|
    result = Demo::Staff.call

    unless result.errors.empty?
      result.errors.each do |error|
        Rails.logger.fatal do
          "Error creating staff accounts: #{Lev::ErrorTranslator.translate(error)}"
        end
      end

      fail 'Failed to create staff accounts'
    end
  end

  desc 'Imports demo book content'
  task :books, [ :config, :version ] => :log_to_stdout do |tt, args|
    configuration = OpenStax::Exercises::V1.configuration

    raise(
      'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET env vars' +
      ' and then restart any background job workers to use bin/rake demo:books'
    ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)

    options = args.to_h
    configs = Demo::Config::Book.dir(options[:config] || :all)
    Delayed::Worker.with_delay_jobs(true) do
      configs.each { |config| Demo::Books.perform_later options.merge(config: config) }
    end
    log_background_job_info configs.size
    log_worker_mem_info
  end

  desc <<~DESC
    Creates demo courses
    Calling this rake task directly will make it attempt to find and reuse the last demo books
  DESC
  task :courses, [ :config ] => :log_to_stdout do |tt, args|
    options = args.to_h
    configs = Demo::Config::Course.dir(options[:config] || :all)
    Delayed::Worker.with_delay_jobs(true) do
      configs.each { |config| Demo::Courses.perform_later options.merge(config: config) }
    end
    log_background_job_info configs.size
  end

  desc <<~DESC
    Creates demo assignments for the demo courses
    Calling this rake task directly will make it attempt to find and reuse the last demo courses
  DESC
  task :tasks, [ :config, :random_seed ] => :log_to_stdout do |tt, args|
    options = args.to_h
    configs = Demo::Config::Course.dir(options[:config] || :all)
    Delayed::Worker.with_delay_jobs(true) do
      configs.each { |config| Demo::Tasks.perform_later options.merge(config: config) }
    end
    log_background_job_info configs.size
  end

  desc <<~DESC
    Works demo student assignments
    Calling this rake task directly will make it attempt to find and reuse the last demo assignments
  DESC
  task :work, [ :config, :random_seed ] => :log_to_stdout do |tt, args|
    options = args.to_h
    configs = Demo::Config::Course.dir(options[:config] || :all)
    Delayed::Worker.with_delay_jobs(true) do
      configs.each { |config| Demo::Work.perform_later options.merge(config: config) }
    end
    log_background_job_info configs.size
  end

  desc 'Shows demo student assignments that would be created by the demo script'
  task :show, [ :config ] => :log_to_stdout do |tt, args|
    Demo::Show.call(args.to_h)
  end
end
