DEFAULT_DEMO_CONFIG = 'review'
DEMO_CONFIG_BASE_DIR = File.join Rails.root, 'config', 'demo'

def abort_if_exercises_unconfigured(task_name)
  configuration = OpenStax::Exercises::V1.configuration

  raise(
    'Please set the OPENSTAX_EXERCISES_CLIENT_ID and OPENSTAX_EXERCISES_SECRET env vars' +
    " and then restart any background job workers to use bin/rake #{task_name}"
  ) if !Rails.env.test? && (configuration.client_id.blank? || configuration.secret.blank?)
end

def demo_routine(routine_class, method_name, types, args)
  method_name = method_name.to_sym
  options = args.to_h.deep_symbolize_keys
  filter = (options.delete(:config) || DEFAULT_DEMO_CONFIG).to_s

  routine_args = Hash.new { |hash, key| hash[key] = options.dup }.tap do |options_by_basename|
    [ types ].flatten.each do |type|
      type_string = type.to_s
      base_dir = File.join(DEMO_CONFIG_BASE_DIR, type_string, filter)
      representer_class = Api::V1::Demo.const_get(type_string.capitalize)::Representer

      Dir[File.join(base_dir, '**', '[^_]*.yml{,.erb}')].each do |path|
        string = File.read(path)
        if File.extname(path) == '.erb'
          erb = ERB.new(string)
          erb.filename = path
          string = erb.result
        end
        representer_hash = representer_class.new(YAML.load(string)).to_hash.deep_symbolize_keys
        options_by_basename[path.sub(base_dir, '')][type.to_sym] = representer_hash
      end
    end
  end.values
  num_routines = routine_args.size

  errors = []
  Delayed::Worker.with_delay_jobs(true) do
    routine_args.each do |routine_arg|
      result = routine_class.public_send method_name, routine_arg
      next if method_name == :perform_later

      errors.concat result.errors
    end
  end

  if method_name == :perform_later
    Rails.logger.info do
      "#{num_routines} background job(s) queued\n" +
      "Manage background workers: bin/delayed_job -n #{num_routines} status/start/stop\n" +
      'Check job status: bin/rake jobs:status'
    end
  elsif errors.empty?
    Rails.logger.info { "#{routine_class.name} successfully ran #{num_routines} time(s)" }
  else
    Rails.logger.fatal do
      "Error(s) running #{routine_class.name}:\n  #{
        errors.map { |error| Lev::ErrorTranslator.translate(error) }.join("\n  ")
      }"
    end

    fail "#{routine_class.name} failed with error(s)"
  end
end

def log_worker_mem_info
  Rails.logger.info { 'Make sure to have ~4G free memory per background worker' }
end

desc 'Initializes all demo data. Config can be either be "all" or a specific config dirname.'
task :demo, [ :config, :version, :random_seed ] => :log_to_stdout do |task, args|
  abort_if_exercises_unconfigured 'demo'

  demo_routine Demo::All, :perform_later, [ 'users', 'import', 'course', 'assign', 'work' ], args

  log_worker_mem_info
end

namespace :demo do
  desc 'Creates demo user accounts'
  task users: :log_to_stdout do |task, args|
    demo_routine Demo::Users, :call, 'users', args.to_h.merge(config: '')
  end

  desc 'Imports demo book content'
  task :import, [ :config, :version ] => :log_to_stdout do |task, args|
    abort_if_exercises_unconfigured 'demo:import'

    demo_routine Demo::Import, :perform_later, 'import', args

    log_worker_mem_info
  end

  desc <<~DESC
    Creates demo courses
    Calling this rake task directly will make it attempt to reuse the last catalog offerings created
  DESC
  task :courses, [ :config ] => :log_to_stdout do |task, args|
    demo_routine Demo::Course, :perform_later, 'course', args
  end

  desc <<~DESC
    Creates demo assignments for the demo courses
    Calling this rake task directly will make it attempt to find and reuse the last demo courses
  DESC
  task :assign, [ :config, :random_seed ] => :log_to_stdout do |task, args|
    demo_routine Demo::Assign, :perform_later, 'assign', args
  end

  desc <<~DESC
    Works demo student assignments
    Calling this rake task directly will make it attempt to find and reuse the last demo assignments
  DESC
  task :work, [ :config, :random_seed ] => :log_to_stdout do |task, args|
    demo_routine Demo::Work, :perform_later, 'work', args
  end

  desc 'Shows demo student assignments that would be created by the demo script'
  task :show, [ :config ] => :log_to_stdout do |task, args|
    demo_routine Demo::Show, :call, [ 'assign', 'work' ], args
  end
end
