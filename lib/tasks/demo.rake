desc 'Initializes data for the deployment demo (run all demo:* tasks), book can be either all, bio or phy.'
task :demo, [:book, :random_seed] => :environment do |tt, args|
  filenames = Dir.glob('lib/tasks/demo_[0-9]*.rb').sort
  filenames.each do |filename|
    base_name = File.basename(filename, '.rb')
    puts "Running #{base_name}"
    require "tasks/#{base_name}"
    class_name = base_name.classify
    result = class_name.constantize.call(args.to_h.merge(print_logs: true))

    if result.errors.none?
      puts "#{base_name} Success!"
    else
      result.errors.each{ |error| puts "#{base_name} Error: " + Lev::ErrorTranslator.translate(error) }
      break
    end
  end
end
