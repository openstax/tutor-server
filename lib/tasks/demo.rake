desc 'Initializes data for the deployment demo (run all demo:* tasks), book can be either all, bio or phy.'
task :demo, [:config, :version, :random_seed] => :environment do |tt, args|
  failures = []
  Rake::Task[:"demo:content"].invoke(args[:config], args[:version], args[:random_seed]) \
    rescue failures << 'Content'
  Rake::Task[:"demo:tasks"].invoke(args[:config], args[:random_seed]) \
    rescue failures << 'Tasks'
  unless ENV['NOWORK']
    Rake::Task[:"demo:work"].invoke(args[:config], args[:random_seed]) \
      rescue failures << 'Work'
  end

  if failures.empty?
    puts 'All demo tasks successful!'
  else
    fail "Some demo tasks failed! (#{failures.join(', ')})"
  end
end

namespace :demo do
  require_relative 'demo'

  desc 'Initializes book content for the deployment demo'
  task :content, [:config, :version, :random_seed] => :environment do |tt, args|

    result = Demo::Content.call(args.to_h.merge(print_logs: true))

    if result.errors.none?
      puts "Successfully imported content"
    else
      result.errors.each{ |error| puts "Content Error: " + Lev::ErrorTranslator.translate(error) }
      fail "Failed to import content"
    end
  end

  desc 'Creates assignments for students'
  task :tasks, [:config, :random_seed] => :environment do |tt, args|

    result = Demo::Tasks.call(args.to_h.merge(print_logs: true))

    if result.errors.none?
      puts "Successfully created tasks"
    else
      result.errors.each{ |error| puts "Tasks Error: " + Lev::ErrorTranslator.translate(error) }
      fail "Failed to create tasks"
    end
  end

  desc 'Works student assignments'
  task :work, [:config, :random_seed] => :environment do |tt, args|

    result = Demo::Work.call(args.to_h.merge(print_logs: true))

    if result.errors.none?
      puts "Successfully worked tasks"
    else
      result.errors.each{ |error| puts "Tasks Error: " + Lev::ErrorTranslator.translate(error) }
      fail "Failed to work tasks"
    end
  end

  desc 'Output student assignments'
  task :show, [:config, :version, :random_seed] => :environment do |tt, args|
    require_relative 'demo/show'

    Demo::Show.call(args.to_h.merge(print_logs: true))
  end
end
