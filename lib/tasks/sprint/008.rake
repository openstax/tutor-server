namespace :sprint do
  desc 'Sprint 8'
  task :'008', [:username] => :environment do |t, args|
    require_relative 'sprint_008/main.rb'
    result = Sprint008::Main.call

    if result.errors.none?
      puts 'Added teacher, student, and teacher_and_student users. Added courses/1 and courses/2.'
      puts "Added task_plan id #{result.outputs.stats_task_plan.id} with 30 students that have partially completed tasks"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
