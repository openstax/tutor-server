namespace :sprint do
  desc 'Sprint 8'
  task :'008courses' => :environment do
    require_relative 'sprint_008/courses.rb'
    result = Sprint008::Courses.call

    if result.errors.none?
      puts "Added users 'student,' 'teacher,' and 'both'"
      puts "Added courses 'Being Taken,' 'Being Taught,' and 'Both'"
      puts "Added 'student' as a student to 'Being Taken'"
      puts "Added 'teacher' as a teacher to 'Being Taught'"
      puts "Added 'both' as a teacher and student to 'Both'"
      puts "Added task plans and tasks for users"
    else
      result.errors.each { |e| puts "Error: " + Lev::ErrorTranslator.translate(e) }
    end
  end
end
