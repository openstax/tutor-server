desc <<-DESC.strip_heredoc
  Initializes data for the deployment demo (run all demo:* tasks)
  Book can be either all, bio, phys or soc.
DESC
task :demo, [ :config, :version, :random_seed ] => :log_to_stdout do |tt, args|
  Rails.logger.info do
    max_processes = Demo::Base.max_processes

    case max_processes
    when 0
      'Using inline processing (DEMO_MAX_PROCESSES = 0)'
    when 1
      "Using 1 child process (DEMO_MAX_PROCESSES = 1)"
    else
      "Using up to #{max_processes} child processes (DEMO_MAX_PROCESSES = #{max_processes})"
    end
  end

  Rake::Task[:'demo:staff'].invoke unless ENV['SKIP_STAFF']
  Rake::Task[:'demo:books'].invoke(args[:config], args[:version]) unless ENV['SKIP_BOOKS']

  unless ENV['SKIP_COURSES']
    Rake::Task[:'demo:courses'].invoke(args[:config])

    unless ENV['SKIP_TASKS']
      Rake::Task[:'demo:tasks'].invoke(args[:config], args[:random_seed])

      Rake::Task[:'demo:work'].invoke(args[:config], args[:random_seed]) unless ENV['SKIP_WORK']
    end
  end

  Rails.logger.info { 'All demo tasks successful!' }
end

namespace :demo do
  desc 'Creates staff user accounts for the deployment demo'
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

  desc 'Imports book content for the deployment demo'
  task :books, [ :config, :version ] => :log_to_stdout do |tt, args|
    result = Demo::Books.call(args.to_h)

    unless result.errors.empty?
      result.errors.each do |error|
        Rails.logger.fatal { "Error importing books: #{Lev::ErrorTranslator.translate(error)}" }
      end

      fail 'Failed to import books'
    end
  end

  desc <<-DESC.strip_heredoc
    Creates courses for the deployment demo
    Calling this rake task directly will make it attempt to find and reuse the last demo books
  DESC
  task :courses, [ :config ] => :log_to_stdout do |tt, args|
    result = Demo::Courses.call(args.to_h)

    unless result.errors.empty?
      result.errors.each do |error|
        Rails.logger.fatal { "Error creating courses: #{Lev::ErrorTranslator.translate(error)}" }
      end

      fail 'Failed to create courses'
    end
  end

  desc <<-DESC.strip_heredoc
    Creates assignments for students
    Calling this rake task directly will make it attempt to find and reuse the last demo courses
  DESC
  task :tasks, [ :config, :random_seed ] => :log_to_stdout do |tt, args|
    result = Demo::Tasks.call(args.to_h)

    unless result.errors.empty?
      result.errors.each do |error|
        Rails.logger.fatal { "Error creating tasks: #{Lev::ErrorTranslator.translate(error)}" }
      end

      fail 'Failed to create tasks'
    end
  end

  desc <<-DESC.strip_heredoc
    Works student assignments
    Calling this rake task directly will make it attempt to find and reuse the last demo assignments
  DESC
  task :work, [ :config, :random_seed ] => :log_to_stdout do |tt, args|
    result = Demo::Work.call(args.to_h)

    unless result.errors.empty?
      result.errors.each do |error|
        Rails.logger.fatal { "Error working assignments: #{Lev::ErrorTranslator.translate(error)}" }
      end

      fail 'Failed to work tasks'
    end
  end

  desc 'Shows student assignments that would be created by the demo script'
  task :show, [ :config ] => :log_to_stdout do |tt, args|
    Demo::Show.call(args.to_h)
  end
end
