namespace :sprint do
  desc 'Sprint 8'
  task :'008', [:username] => :environment do |t, args|
    require_relative 'sprint_008/main.rb'
    result = Sprint008::Main.call

    if result.errors.none?
      puts 'Added teacher and student users. See their dashboards.'
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
