namespace :sprint do
  desc 'Sprint 8'
  task :'008tryanother', [:username] => :environment do |t, args|
    require_relative 'sprint_008/try_another.rb'
    result = Sprint008::TryAnother.call

    if result.errors.none?
      puts 'Added teacher and student users. See their dashboards.'
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
