namespace :sprint do
  desc 'Sprint 9 Course Stats'
  task :'009course_stats' => :environment do |tt, args|
    require_relative 'sprint_009/course_stats.rb'
    course = Sprint009::CourseStats[]

    puts "*== Course Stats API ==*"
    puts ""
    puts "Login as 'student'"
    puts ""
    puts "visit /api/course/#{course.id}/stats"
    puts ""
    puts "*======================*"
  end
end
