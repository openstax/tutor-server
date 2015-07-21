desc 'Initializes data for the deployment demo (run all demo:* tasks), book can be either all, bio or phy.'
task :demo, [:book, :random_seed] => [
       'demo:content', 'demo:tasks', 'demo:work'
     ] do
  puts 'All demo tasks completed'
end

namespace :demo do

  desc 'Initializes book content for the deployment demo'
  task :content, [:book, :random_seed] => :environment do |tt, args|
    require_relative 'demo/content'
    result = DemoContent.call(args.to_h.merge(print_logs: true))
    if result.errors.none?
      puts "Content Success!"
    else
      result.errors.each{ |error| puts "Content Error: " + Lev::ErrorTranslator.translate(error) }
      fail "demo content failed"
    end
  end

  desc 'Creates assignments for students'
  task :tasks, [:book, :random_seed] => :environment do |tt, args|
    require_relative 'demo/tasks'
    result = DemoTasks.call(args.to_h.merge(print_logs: true))
    if result.errors.none?
      puts "Tasks creation success!"
    else
      result.errors.each{ |error| puts "Tasks Error: " + Lev::ErrorTranslator.translate(error) }
      fail "task creation failed"
    end
  end

  desc 'Works student assignments '
  task :work, [:book, :random_seed] => :environment do |tt, args|
    require_relative 'demo/work'
    result = DemoWork.call(args.to_h.merge(print_logs: true))
    if result.errors.none?
      puts "Tasks were worked successfully!"
    else
      result.errors.each{ |error| puts "Tasks Error: " + Lev::ErrorTranslator.translate(error) }
      fail "working tasks failed"
    end
  end

end
