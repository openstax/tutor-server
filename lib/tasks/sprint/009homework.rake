namespace :sprint do
  desc 'Sprint 9'
  task :'009homework', [:username] => :environment do |t, args|
    require_relative 'sprint_009/homework.rb'
    result = Sprint009::Homework.call

    if result.errors.none?
      puts 'Added teacher and student users. See their dashboards.'
    else
      result.errors.each{ |error|
        puts "Error: " + Lev::ErrorTranslator.translate(error)
      }
    end
  end
end
