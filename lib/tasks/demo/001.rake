namespace :demo do
  desc 'Initializes data for the deployment demo'
  task :'001', [:book, :book_version, :random_seed] => :environment do |tt, args|
    require 'tasks/demo_001'
    result = Demo001.call(args.to_h.merge(print_logs: true))

    if result.errors.none?
      puts "Success!"
    else
      result.errors.each{ |error| puts "Error: " + Lev::ErrorTranslator.translate(error) }
    end
  end
end
