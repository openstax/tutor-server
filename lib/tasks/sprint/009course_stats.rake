namespace :sprint do
  desc 'Sprint 9 Course Stats'
  task :'009course_stats' => :environment do |tt, args|
    require_relative 'sprint_009/course_stats.rb'
    course = Entity::Course.find(ENV['COURSE_ID'])
    result = Sprint009::CourseStats.call(course: course)

    if result.errors.none?
      puts result.outputs.course_stats.to_json
    else
      result.errors.each{|error| puts "Error: " + Lev::ErrorTranslator.translate(error)}
    end
  end
end
