namespace :sprint do
  desc 'Sprint 7A'
  task :'007a', [:username] => :environment do |t, args|
    require_relative 'sprint_007_a/main.rb'
    result = Sprint007A::Main.call

    if result.errors.none?
      puts 'Added teacher and student users. See their dashboards.'
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
