namespace :sprint do
  desc 'Sprint 9 Course Stats'
  task :'009course_stats' => :environment do |tt, args|
    puts "Hey there! Now importing a book and creating a course..."
    puts ""
    puts ""
    puts ""
    puts "... please be incredibly patient ..."
    puts ""
    puts ""
    puts ""
    puts "... like, no joke... Just go take your lunch now..."

    require_relative 'sprint_009/course_stats.rb'
    course = Sprint009::CourseStats[]

    puts "*== Course Stats API ==*"
    puts "/api/course/#{course.id}/stats"
    puts "*======================*"
  end
end
