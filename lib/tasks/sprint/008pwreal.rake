namespace :sprint do
  desc 'Sprint 8'
  task :'008pwreal', [:username] => :environment do |t, args|
    require_relative 'sprint_008/pw_real.rb'
    result = Sprint008::PwReal.call
    outputs = result.outputs

    if result.errors.none?
      tags = outputs.task.task_steps.collect{ |ts| 
              OpenStax::Exercises::V1::Exercise.new(ts.tasked.content).tags
             }

      puts "For book #{outputs.book_id} and course #{outputs.course.id}, created a practice " + 
           "widget searching for recommended problems in BigLearn matching #{OpenStax::BigLearn::V1.real_client.stringify_tag_search(outputs.condition)}.  " + 
           "The practice widget has #{outputs.task.task_steps.count} exercises with " +
           "these tags: #{tags.inspect}"
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
