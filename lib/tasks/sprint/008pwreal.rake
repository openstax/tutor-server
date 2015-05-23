namespace :sprint do
  desc 'Sprint 8'
  task :'008pwreal', [:username] => :environment do |t, args|
    require_relative 'sprint_008/pw_real.rb'
    result = Sprint008::PwReal.call
    outputs = result.outputs

    if result.errors.none?
      exercises = outputs.task.task_steps.collect{ |ts|
        OpenStax::Exercises::V1::Exercise.new(content: ts.tasked.content)
      }

      puts "For book #{outputs.book_id} and course #{outputs.course.id}, created a practice " +
           "widget searching for recommended problems in Biglearn matching\n\n#{OpenStax::Biglearn::V1.real_client.stringify_tag_search(outputs.condition)}\n\n" +
           "The practice widget has #{outputs.task.task_steps.count} exercises:\n\n"

      exercises.each_with_index do |ex, ii|
        puts "(##{ii}) UID = #{ex.uid} TAGS = #{ex.tags.join(', ')}\n"
      end

    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
