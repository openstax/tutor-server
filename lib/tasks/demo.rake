def abort_if_exercises_unconfigured(task_name)
  configuration = OpenStax::Exercises::V1.configuration

  raise(
    'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET env vars' +
    " and then restart any background job workers to use bin/rake #{task_name}"
  ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)
end

def demo_routine_perform_later(routine_class, type_string, args)
  type_string = type_string.to_s
  options = args.to_h.deep_symbolize_keys
  types = type_string == 'all' ? [ 'import', 'users', 'course', 'assign', 'work' ] : [ type_string ]
  filter = (options.delete(:config) || Demo::DEFAULT_CONFIG).to_s

  configs = Hash.new { |hash, key| hash[key] = options.dup }.tap do |options_by_basename|
    types.each do |type|
      Dir[File.join(Demo::CONFIG_BASE_DIR, '**', type, '**/[^_]*.yml{.erb,}')].select do |path|
        path.include? filter
      end.each do |path|
        string = File.read(path)
        if File.extname(path) == '.erb'
          erb = ERB.new(string)
          erb.filename = path
          string = erb.result
        end
        options_by_basename[path.sub("/#{type}/", '/').chomp('.erb')][type] = YAML.load(string)
      end
    end
  end.values
  routine_args = configs.map do |config|
    next Api::V1::Demo::AllRepresenter.new(Hashie::Mash.new).from_hash(config).deep_symbolize_keys \
      if type_string == 'all'

    {}.tap do |routine_arg|
      config.each do |key, value|
        routine_arg[key.to_sym] = Api::V1::Demo.const_get(key.capitalize)::Representer.new(
          Hashie::Mash.new
        ).from_hash(value).deep_symbolize_keys
      end
    end
  end
  num_routines = routine_args.size

  Delayed::Worker.with_delay_jobs(true) do
    routine_args.each { |routine_arg| routine_class.perform_later routine_arg }
  end

  Rails.logger.info do
    <<~INFO
      #{num_routines} background job(s) queued
      Check job status: bin/rake jobs:status
      Manage background workers: bin/delayed_job -n #{num_routines} status/start/stop
      Or run the jobs inline (single process): bin/rake jobs:workoff
    INFO
  end
end

def log_worker_mem_info
  Rails.logger.info { 'Make sure to have ~4G free memory per background worker' }
end

desc 'Initializes all demo data. Config can be either be "all" or a specific config dirname.'
task :demo, [ :config, :version, :random_seed ] => :log_to_stdout do |task, args|
  abort_if_exercises_unconfigured 'demo'

  demo_routine_perform_later Demo::All, 'all', args

  log_worker_mem_info
end

namespace :demo do
  desc 'Creates demo user accounts'
  task :users, [ :config ] => :log_to_stdout do |task, args|
    demo_routine_perform_later Demo::Users, 'users', { config: '' }.merge(args.to_h)
  end

  desc 'Imports demo book content'
  task :import, [ :config, :version ] => :log_to_stdout do |task, args|
    abort_if_exercises_unconfigured 'demo:import'

    demo_routine_perform_later Demo::Import, 'import', args

    log_worker_mem_info
  end

  desc <<~DESC
    Creates demo courses
    Calling this rake task directly will make it attempt to reuse the last catalog offerings created
  DESC
  task :courses, [ :config ] => :log_to_stdout do |task, args|
    demo_routine_perform_later Demo::Course, 'course', args
  end

  desc <<~DESC
    Creates demo assignments for the demo courses
    Calling this rake task directly will make it attempt to find and reuse the last demo courses
  DESC
  task :assign, [ :config, :random_seed ] => :log_to_stdout do |task, args|
    demo_routine_perform_later Demo::Assign, 'assign', args
  end

  desc <<~DESC
    Works demo student assignments
    Calling this rake task directly will make it attempt to find and reuse the last demo assignments
  DESC
  task :work, [ :config, :random_seed ] => :log_to_stdout do |task, args|
    demo_routine_perform_later Demo::Work, 'work', args
  end
end
